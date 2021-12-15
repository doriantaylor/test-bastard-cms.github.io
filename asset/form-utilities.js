var FormUtils = (function () {
    var coerceNumber = function (x, neg) {
        if (neg !== null) {
            if (typeof neg === 'undefined') neg = false;
            if (neg === false) neg = Infinity;
            else if (neg === true) neg = -Infinity;
            else {
                if (typeof neg !== 'number') neg = parseFloat(neg);
                if (isNaN(neg))
                    throw 'neg must be null, true, false, or number-able';
            }
        }
        
        var tx = typeof x;
        if (tx === 'undefined' || x.toString().match(/^\D*$/)) return neg;
        if (tx != 'number') x = parseFloat(x);
        if (isNaN(x)) throw 'x has to be number-able';
        
        return x;
    };

    var reliableCoord = function (e, y) {
        var member = y ? 'clientY' : 'clientX';
        return e.changedTouches ? e.changedTouches[0][member] : e[member];
    };

    var spinNumeric = function (coords, val, min, max, step) {
        var r  = coords.r;
        var th = coords.theta * -180 / Math.PI;

        var sign = (th < -45 || th > 135) ? -1 : 1;
        var nval = val + Math.round(Math.pow(r, 1/3)) * sign * step;
        if (nval < min || nval > max) return null;

        return nval;
    };

    var dispatchChange = function (elem) {
        var change = new CustomEvent('change', { bubbles: true });
        elem.dispatchEvent(change);
        return true;
    };

    var jogNumeric = function (e) {
        if (e.code == 'ArrowUp' || e.code == 'ArrowDown') {
            //console.log(e.code);
            dispatchChange(this);
            return true;
        }
        return false;
    };

    var bindNumeric = function (elem, interpret, thenWhat) {
        if (typeof elem == 'string') elem = document.getElementById(elem);
        if (elem.nodeType != 1 || typeof elem.value == 'undefined')
            throw 'Elem must be a form input';

        // give us a default interpretation of the mouse event
        if (typeof interpret !== 'function') interpret = spinNumeric;

        // give us a default action
        if (typeof thenWhat !== 'function') thenWhat = dispatchChange;
        var omm; // declare mousemove here
        var tid;

        var omd = function (e) {
            // turns out you can't use the control if you prevent default omd
            if (e.changedTouches) e.preventDefault();
            //console.log('omd fired');

            // x and y coordinates at mouse down
            var sx = reliableCoord(e);
            var sy = reliableCoord(e, true);

            // x and y will always be the current coordinates
            var x = sx, y = sy;
        
            // define mousemove as a closure within mousedown
            omm = function (e) {
                e.preventDefault();

                // deal with off-screen messup
                if (typeof e.buttons === 'number' && e.buttons === 0) {
                    var ev = new CustomEvent('mouseup');
                    window.dispatchEvent(ev);
                    return false;
                }
                
                var coords = {
                    sx: sx, sy: sy, x: x, y: y, dx: 0, dy: 0, r: 0, theta: 0,
                    mx: reliableCoord(e),
                    my: reliableCoord(e, true),
                };

                coords.dx = coords.mx - x;
                coords.dy = coords.my - y;
                coords.r  = Math.sqrt(Math.pow(coords.dx, 2) + 
                                      Math.pow(coords.dy, 2));
                coords.theta = Math.atan2(coords.dy, coords.dx);

                // smuggle these values back out;
                x = coords.mx;
                y = coords.my;

                var min  = coerceNumber(elem.min, true);
                var max  = coerceNumber(elem.max);
                var step = coerceNumber(elem.step, 1);
                var val  = coerceNumber(elem.value, 0);
                var out  = interpret(coords, val, min, max, step);

                // only do this if there is an actual change
                if (typeof out === 'number' && !isNaN(out) && out !== val) {
                    var log = Math.floor(Math.log10(step));
                    if (log < 0) {
                        var ten = Math.pow(10, -log);
                        out = Math.round(out * ten) / ten;
                    }

                    elem.value = out;

                    if (tid) window.clearTimeout(tid);
                    tid = window.setTimeout(function () {
                        thenWhat(elem);
                        tid = null;
                    }, 25);

                    return true; // propagate
                }

                return false;
            };

            // note we add these to the *window*
            window.addEventListener('mousemove', omm, false);
            window.addEventListener('touchmove', omm, false);
        };

        // and we add the mousedown to the *element*
        elem.addEventListener('mousedown',  omd, false);
        elem.addEventListener('touchstart', omd, false);

        var omu;
        omu = function (e) {
            e.stopPropagation();
            if (omm) {
                //console.log('omu fired', e);
                window.removeEventListener('mousemove', omm, false);
                window.removeEventListener('touchmove', omm, false);
                omm = null;

                if (tid) {
                    window.clearTimeout(tid);
                    thenWhat(elem);
                    tid = null;
                }
            }
        };

        // and finally, the mouseup goes to the window
        window.addEventListener('mouseup',  omu, false);
        window.addEventListener('touchend', omu, false);
    };


    var inflect = function (elem) {
        if (!elem.form) throw 'element ' + elem + ' is not in a form!';

        if (typeof elem.inflect === 'undefined') {
            for (var p = elem.parentNode; p.parentNode; p = p.parentNode) {
                if (p.className.trim().split().indexOf('inflect') >= 0) {
                    elem.inflect = p;
                    break;
                }
            }
            if (!elem.inflect) elem.inflect = null;
        }

        if (elem.inflect) {
            var sings = Array.from(elem.inflect.querySelectorAll('.singular'));
            var plurs = Array.from(elem.inflect.querySelectorAll('.plural'));

            if (parseFloat(elem.value.replace(/[^0-9.]+/g, '')) === 1) {
                sings.forEach(function (e) { e.style.display = ''; });
                plurs.forEach(function (e) { e.style.display = 'none'; });
            }
            else {
                sings.forEach(function (e) { e.style.display = 'none'; });
                plurs.forEach(function (e) { e.style.display = ''; });
            }
        }
    };

    // XXX IS THIS EVIL???
    HTMLInputElement.prototype.snug = function () {
        if (typeof this.form.charWidth === 'number' &&
            typeof this.form.paddingEms === 'number') {
            return this.style.width = (this.value.length * this.form.charWidth +
                                       this.form.paddingEms).toFixed(3) + 'em';
        }
        return null;
    };

    var numericDefault = function (str, defaultVal) {
        var out = parseFloat(str);
        return isNaN(out) ? defaultVal : out;
    };

    var setMinMax = function (elem) {
        if (typeof elem.hardMin === 'undefined') {
            elem.hardMin = numericDefault(elem.min, -Infinity);
        }
        if (typeof elem.hardMax === 'undefined') {
            elem.hardMax = numericDefault(elem.max, Infinity);
        }
    };

    var initRange = function (elem) {
        if (!elem.form) throw 'element ' + elem + ' is not in a form!';

        setMinMax(elem);

        // we get the attribute value because elem.value may be different
        var value = numericDefault(elem.getAttribute('value'));
        var step  = numericDefault(elem.step, 1);
        var other = elem.counterpart;
        if (typeof other === 'undefined') {
            var range;
            for (var p = elem.parentNode; p.parentNode; p = p.parentNode) {
                if (p.className.trim().split().indexOf('range') >= 0) {
                    elem.range = range = p;
                    break;
                }
            }

            if (range) {
                var cand = Array.from(
                    range.querySelectorAll('input[type=number]'));
                //console.log(cand);
                if (cand.length != 2)
                    throw "There must be exactly two inputs in the range";
                other = elem.counterpart = cand.filter(
                    function (x) { return x != elem; })[0];

                // set hard min and hard max
                setMinMax(other);

                var cs = numericDefault(other.step, 1);
                if (step != cs) throw '@step in ' + elem.name + ' and ' +
                    other.name + ' do not match';
                if (!(isFinite(elem.hardMax) && isFinite(other.hardMin) ||
                      isFinite(elem.hardMin) && isFinite(other.hardMax)))
                    throw '@max and @min must be defined for the ' + 
                    'lower and higher of ' + elem.name + ' and ' +
                    other.name + ', respectively.';

                // XXX not sure if i want this here but ehh
                if (typeof range.gap === 'undefined') {
                    // diff is the difference between the smaller max
                    // and the greater min
                    cand.sort(
                        function (a, b) { return a.hardMin - b.hardMin; });
                    var gap = cand[1].hardMin - value;
                    if (gap < 0) throw 'Ranges ' + elem.name + ' and ' +
                        other.name + ' overlap!';

                    range.gap = gap;

                    // set the min and max to the full gamut
                    cand[1].min = cand[0].min;
                    cand[0].max = cand[1].max;
                }
            }
            else {
                elem.range       = null;
                elem.counterpart = null;
            }
        }
    };

    var handleRange = function (elem) {

        var value = parseFloat(elem.value);
        var step  = numericDefault(elem.step, 1);

        var other = elem.counterpart;
        if (!other || !elem.range) return;

        // get other's value
        var otherVal = parseFloat(other.value);
        if (isNaN(otherVal)) {
            throw 'otherval is nan';
            otherVal    = other.origValue;
            other.value = other.origValue.toString();
        }

        // get mins and maxes
        var min = numericDefault(elem.min, -Infinity);
        var max = numericDefault(elem.max,  Infinity);
        var otherMin = numericDefault(other.min, -Infinity);
        var otherMax = numericDefault(other.max,  Infinity);
            
        // get the gap between the two canonical values
        var gap = elem.range.gap;

        //console.log(elem.name, other.name, elem.hardMin, other.hardMax, gap);

        if (elem.hardMax <= other.hardMax) {
            // we are the smaller one

            // this shouldn't happen
            if (value > max) elem.value = value = max;

            /*
              we assume the range has been initialized with:

              other.min - elem.value == other.value - elem.max

              ie there is a gap of >= 0


              - we always want elem.max to be at least one step above
                value as long as it is less than or equal to otherMax - gap
              - we always want other.min to be exactly value + gap
            */

            // if (value + step + gap <= otherMax) elem.max = value + step;
            //if (value - step + gap >= min) other.min = value - step + gap;

            //console.log(otherVal, other.origValue);

            if (otherVal <= value + gap) other.value = value + gap;
            //else if (value + gap < otherVal) {
            else {
                other.value = (value + gap > other.origValue) ?
                    value + gap : other.origValue;
            }
        }
        else {
            // we are the bigger one
            if (value < min) elem.value = value = min;

            // if the other value is less t
            //console.log(value - gap, otherVal);

            if (otherVal >= value - gap) other.value = value - gap;
            else other.value = (value - gap < other.origValue) ? 
                value - gap : other.origValue;
        }
        
        // we will be automatically inflected so do the other one
        inflect(elem.counterpart);
        elem.counterpart.snug();
    };

    var CHANGEFUNC = function (e) { this.form.recalculate(); };

    var loadEvent = function (form, recalcFunc, changeFunc) {
        if (typeof form !== 'object') {
            var id = form;
            form = document.getElementById(id);
            if (!form) throw 'No form found with ID ' + id;
        }

        var ruler = document.querySelector('.text-metric-ruler');
        if (ruler) {
            var style = window.getComputedStyle(ruler);
            var tw    = ruler.offsetWidth / ruler.textContent.length;
            var em    = parseFloat(style.fontSize); // in pixels
            form.charWidth = tw / em;
            if (!form.paddingEms) form.paddingEms = 1;
        }

        // set a default change function
        if (!changeFunc) changeFunc = CHANGEFUNC;

        return function () {
            form.recalculate = recalcFunc;

            var inputs = form.querySelectorAll('input[type=number]');
            for (var i = 0; i < inputs.length; i++) {
                var input = inputs[i];
                var name  = input.name;
                var value = parseFloat(input.value);
                if (!isNaN(value)) input.origValue = value;

                // initialize ranges and inflect
                initRange(input);
                inflect(input);

                // changeFunc[''] will be the default if changeFunc is an obj
                input.changeFunc = changeFunc;
                if (typeof input.changeFunc === 'object') {
                    input.changeFunc = (changeFunc[name] ?changeFunc[name] :
                                        changeFunc['']) || CHANGEFUNC;
                }

                var wrap = function (e) {
                    //console.log(e.target);
                    // first we get the value and reset to origValue
                    // it if it is not a number
                    var value = parseFloat(this.value);
                    if (isNaN(value)) this.value = value = this.origValue;

                    // do this boilerplate before running changefunc
                    handleRange(this);
                    inflect(this);

                    // feeling cute, might delete later
                    this.snug();

                    // penultimately we run the changeFunc if it
                    // exists; do it in the context of the element
                    if (this.changeFunc) this.changeFunc(e);

                    // lastly, we set origValue to the current value
                    this.origValue = value;
                };

                input.addEventListener('change', wrap, false);
                bindNumeric(input);
            }

            form.recalculate();
        };
    };

    var out = {
        coerceNumber:   coerceNumber,
        bindNumeric:    bindNumeric,
        spinNumeric:    spinNumeric,
        dispatchChange: dispatchChange,
        inflect:        inflect,
        loadEvent:      loadEvent
    };

    return out;
})();
