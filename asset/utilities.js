(function () {
    let fragmentLoader = function (e) {
        console.log(window.location);

        // this is weird but this is what you need to do
        if (window.location.hash) {
            console.log('forcing scroll to ' + window.location.hash);
            window.location.hash = window.location.hash;
        }
        return true;
    };

    window.addEventListener('load', fragmentLoader, false);
})();
