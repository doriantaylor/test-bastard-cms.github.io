<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:svg="http://www.w3.org/2000/svg" 
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:rdfa="http://www.w3.org/ns/rdfa#"
                xmlns:xhv="http://www.w3.org/1999/xhtml/vocab#"
                xmlns:str="http://xsltsl.org/string"
                xmlns:uri="http://xsltsl.org/uri"
                xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="html rdf svg xlink rdfa uri xhv str xc">

<xsl:import href="asset/rdfa.xsl"/>
<xsl:import href="asset/transclude.xsl"/>

<!--<xsl:output method="xml" indent="yes" media-type="text/html"/>-->
<xsl:output
    method="html" media-type="application/xhtml+xml" indent="yes"
    omit-xml-declaration="yes"
    encoding="utf-8" doctype-public=""/>
<!--
    doctype-public="-//W3C/DTD XHTML 1.0 Strict//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>
-->
<xsl:key name="linked-abbr" match="html:abbr[ancestor::html:a][not(ancestor::html:dfn)]" use="normalize-space(.)"/>
<xsl:key name="titled-abbr" match="html:abbr[normalize-space(@title) != '']" use="normalize-space(.)"/>
<xsl:key name="linked-dfn" match="html:dfn[ancestor::html:a][not(ancestor::html:abbr)]" use="normalize-space(.)"/>
<xsl:key name="has-main" match="html:main[not(@hidden)]" use="''"/>
<xsl:key name="has-article" match="html:article[ancestor::html:main[not(@hidden)]]|html:article[ancestor::html:body[not(descendant::html:main)]]" use="''"/>

<!--<xsl:variable name="rdfa:DEBUG" select="true()"/>-->

<xsl:template match="html:head">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <head>
    <xsl:apply-templates select="@*" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>
    
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>

    <xsl:apply-templates select="html:*[not(self::html:object)]">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>

    <xsl:for-each select="html:object/*">
      <template>
      <xsl:apply-templates>
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
      </xsl:apply-templates>
      </template>
    </xsl:for-each>
    <link rel="stylesheet" type="text/css" href="stylesheet.css"/>
    <meta name="viewport" content="width=device-width, initial-scale=0.6, maximum-scale=2.0"/>
    <script type="text/javascript" src="asset/utilities.js"></script>
  </head>
</xsl:template>

<xsl:template match="html:body">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="contents">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="predicate" select="'contents'"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="status">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="predicate" select="'http://purl.org/ontology/bibo/status'"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="class">
    <xsl:value-of select="normalize-space(@class)"/>
    <xsl:if test="contains(concat(' ', $status, ' '), ' http://purl.org/ontology/bibo/status/draft ')">
      <xsl:text> draft</xsl:text>
    </xsl:if>
    <xsl:if test="contains(concat(' ', $status, ' '), ' https://privatealpha.com/ontology/content-inventory/1#confidential ')">
      <xsl:text> confidential</xsl:text>
    </xsl:if>
    <xsl:if test="contains(concat(' ', $status, ' '), ' https://privatealpha.com/ontology/content-inventory/1#circulated ')">
      <xsl:text> circulated</xsl:text>
    </xsl:if>
  </xsl:variable>

  <!--<xsl:message>status: (<xsl:value-of select="$status"/>)</xsl:message>-->

  <body>
    <xsl:apply-templates select="@*[name() != 'class']" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>
    <xsl:if test="string-length($class)">
      <xsl:attribute name="class">
        <xsl:value-of select="normalize-space($class)"/>
      </xsl:attribute>
    </xsl:if>

  <header>
    <xsl:variable name="title" select="ancestor-or-self::html:*[html:head/html:title]/html:head[html:title][1]/html:title[1]"/>
    <xsl:if test="not(html:h1) and $title">
      <h1><xsl:apply-templates select="$title//node()"/></h1>
    </xsl:if>
  </header>

  <xsl:variable name="main-elem" select="key('xc:main', '')[1]"/>
  <main>
    <xsl:choose>
    <xsl:when test="$main-elem">
      <xsl:message>lol found main</xsl:message>
      <xsl:apply-templates select="$main-elem/@*" mode="xc:attribute">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
      </xsl:apply-templates>

      <xsl:apply-templates select="$main-elem/*">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="true()"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="html:article">
      <xsl:apply-templates select="html:article">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="true()"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <article>
        <xsl:variable name="toc-document">
          <xsl:call-template name="test-types">
            <xsl:with-param name="base" select="$base"/>
            <xsl:with-param name="types" select="$type"/>
            <xsl:with-param name="in" select="'http://purl.org/ontology/bibo/Manual http://purl.org/ontology/bibo/Specification http://purl.org/ontology/bibo/Standard http://purl.org/ontology/bibo/Report http://purl.org/ontology/bibo/Book'"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:if test="string-length($toc-document)">
          <details class="toc">
            <summary>Table of Contents</summary>
            <xsl:apply-templates select="." mode="toc">
              <xsl:with-param name="base" select="$base"/>
              <xsl:with-param name="resource-path" select="$resource-path"/>
              <xsl:with-param name="rewrite"       select="$rewrite"/>
              <xsl:with-param name="main"          select="true()"/>
              <xsl:with-param name="heading"       select="$heading"/>
            </xsl:apply-templates>
          </details>
        </xsl:if>

        <xsl:apply-templates select="*">
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
          <xsl:with-param name="main"          select="true()"/>
          <xsl:with-param name="heading"       select="$heading"/>
        </xsl:apply-templates>
      </article>
    </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="string-length(normalize-space($contents))">
      <xsl:message>found contents: <xsl:value-of select="$contents"/></xsl:message>
      <xsl:variable name="nav" select="document(normalize-space($contents))"/>
      <xsl:apply-templates select="$nav/html:html" mode="nav">
        <xsl:with-param name="resource-path" select="concat($resource-path, ' ', normalize-space($contents))"/>
        <xsl:with-param name="predicate" select="'contents'"/>
      </xsl:apply-templates>
    </xsl:if>

  </main>

</body>
</xsl:template>

<xsl:template match="html:html" mode="nav">
  <xsl:param name="base" select="normalize-space((/html:html/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="predicate"/>

  <!--<xsl:message><xsl:value-of select="$base"/></xsl:message>-->

  <xsl:variable name="contents">
    <xsl:call-template name="str:unique-tokens">
      <xsl:with-param name="string">
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="predicate" select="'dct:hasPart'"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="raw" select="true()"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="predicate" select="'sioc:host_of'"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="raw" select="true()"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="predicate" select="'sioc:space_of'"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="raw" select="true()"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="predicate" select="'sioc:parent_of'"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="raw" select="true()"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="predicate" select="'sioc:container_of'"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="raw" select="true()"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="string-length(normalize-space($contents))">
    <xsl:message>hi from nav: <xsl:value-of select="$contents"/></xsl:message>
  <nav>
    <ul>
      <xsl:call-template name="nav-li">
        <xsl:with-param name="links" select="$base"/>
      </xsl:call-template>
      <xsl:call-template name="nav-li">
        <xsl:with-param name="links" select="normalize-space($contents)"/>
      </xsl:call-template>
    </ul>
  </nav>
  </xsl:if>
</xsl:template>

<xsl:template name="nav-li">
  <xsl:param name="base" select="normalize-space((/html:html/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="links" select="''"/>

  <xsl:variable name="first">
  <xsl:choose>
    <xsl:when test="contains($links, ' ')">
      <xsl:value-of select="substring-before($links, ' ')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$links"/>
    </xsl:otherwise>
  </xsl:choose>
  </xsl:variable>

  <xsl:variable name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$first"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
      <xsl:with-param name="base" select="$base"/>
      <!--<xsl:with-param name="debug" select="true()"/>-->
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="label">
    <xsl:variable name="st">
      <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
        <xsl:with-param name="subject" select="$first"/>
        <xsl:with-param name="predicate" select="'http://purl.org/ontology/bibo/shortTitle'"/>
        <xsl:with-param name="base" select="$base"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="normalize-space($st) = ''">
        <xsl:variable name="_">
          <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
            <xsl:with-param name="subject" select="$first"/>
            <xsl:with-param name="predicate" select="'http://purl.org/dc/terms/title'"/>
            <xsl:with-param name="base" select="$base"/>
            <!--<xsl:with-param name="debug" select="true()"/>-->
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:value-of select="substring-before($_, $rdfa:UNIT-SEP)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-before($st, $rdfa:UNIT-SEP)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <li>
    <a href="{$first}">
      <xsl:if test="string-length(normalize-space($type))">
        <xsl:attribute name="typeof">
          <xsl:call-template name="rdfa:make-curie-list">
            <xsl:with-param name="list" select="$type"/>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$label"/>
    </a>
  </li>

  <xsl:if test="contains($links, ' ')">
    <xsl:call-template name="nav-li">
      <xsl:with-param name="links" select="substring-after($links, ' ')"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template match="html:body|html:main|html:article" mode="toc">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

<ol>
  <xsl:choose>
    <xsl:when test="count(key('has-article', '')) = 1">
      <xsl:apply-templates select="key('has-article', '')[1]//html:section[not(ancestor::html:section)]" mode="toc">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>

    </xsl:when>
    <xsl:when test="key('has-main', '')">
      <xsl:apply-templates select="key('has-main', '')[1]//html:section[not(ancestor::html:section)]" mode="toc">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select=".//html:section[not(ancestor::html:section)]" mode="toc">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>
</ol>
</xsl:template>

<xsl:template match="html:section[parent::html:body|parent::html:main|parent::html:article]|html:section[not(ancestor::html:aside)][parent::html:section][ancestor::html:section[parent::html:body|parent::html:main|parent::html:article]]" mode="toc">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="fragment" select="concat('#', normalize-space(@id))"/>
  <xsl:variable name="title" select="(html:h1|html:h2|html:h3|html:h4|html:h5|html:h6)[not(preceding-sibling::*)]"/>
  <li>
    <a href="{$fragment}"><xsl:apply-templates select="$title/node()" mode="strip-links-inline"/></a>
    <xsl:if test="html:section">
      <ol>
        <xsl:apply-templates select="html:section" mode="toc">
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
          <xsl:with-param name="main"          select="$main"/>
          <xsl:with-param name="heading"       select="$heading"/>
        </xsl:apply-templates>
      </ol>
    </xsl:if>
  </li>
</xsl:template>

<xsl:template match="html:section
                     [child::html:script[@src][contains(translate(@type, 'XML', 'xml'), 'xml')][not(preceding-sibling::*|following-sibling::*)]]" mode="toc">
<!--                     [parent::html:body|parent::html:main|parent::html:article]|html:section[not(ancestor::html:aside)][parent::html:section][ancestor::html:section[parent::html:body|parent::html:main|parent::html:article]]" mode="toc">-->
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="src">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="uri" select="html:script[1]/@src"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="document">
    <xsl:choose>
      <xsl:when test="contains($src, '#')">
        <xsl:value-of select="substring-before($src, '#')"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$src"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:message><xsl:value-of select="$src"/> LOL LOL LOL IS THIS EVEN BEING RUN </xsl:message>

  <xsl:variable name="path-t" select="concat(' ', normalize-space($resource-path), ' ')"/>
  <xsl:variable name="document-t" select="concat(' ', $document, ' ')"/>

  <xsl:if test="not(contains($path-t, $document-t))">

    <xsl:variable name="actual-doc" select="document($document)/*"/>

    <!-- XXX THIS IS WRONG, the toc will be wrong if the target is a fragment -->

    <xsl:variable name="fragment">
      <xsl:choose>
        <xsl:when test="contains($src, '#')">
          <xsl:value-of select="normalize-space(substring-after($src, '#'))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>#</xsl:text>
          <xsl:value-of select="$actual-doc/html:body[1]/@id"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <li>
      <a href="{$fragment}"><xsl:apply-templates select="$actual-doc/html:head[1]/html:title[1]/node()" mode="strip-links-inline"/></a>
      <xsl:apply-templates select="$actual-doc/html:body[1]" mode="toc">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="concat($resource-path, ' ', $document)"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </li>
  </xsl:if>
</xsl:template>

<xsl:template match="html:a" mode="strip-links-inline">
<span>
  <xsl:apply-templates select="@*[name() != 'href']"/>
  <xsl:if test="@href and not(@resource)">
    <xsl:attribute name="resource">
      <xsl:value-of select="@href"/>
    </xsl:attribute>
  </xsl:if>
  <xsl:apply-templates/>
</span>
</xsl:template>

<xsl:template match="node()" mode="strip-links-inline">
  <xsl:apply-templates select="."/>
</xsl:template>

  <!--
      Ultimately what we are trying to do is replace the <body>
      element of the transcluded document with something appropriate,
      while still preserving the embedded RDF graph structure.

      (Note that the <body> subject may not be the same as the document!)

      (The root element neither! Although we're assuming for now it is.)

      Let's start by asking what we would do if we *didn't* have to
      preserve the graph structure: we would probably just replace the
      transcluding element with the child elements and non-empty text
      children of the transcluded document's <body>.

      (The content model of <body> has been changed in HTML5, from
      just block elements, to include inline elements and text.)

      To preserve the graph structure, we need to wrap the transcluded
      <body> children in a new element; something necessarily other
      than <body>. In simpler times, this could just have been a
      <div>, but now with HTML5's ménagerie of exotic sectioning
      elements, there are a number of new issues to consider.

      Indeed the default behaviour can still be to plunk down a <div>,
      but this behaviour ought to occur only if no other solution can
      be derived.

      The dominant situation would be to explicitly define what the
      containing element should be, by making it the immediate parent
      of the transcluding element, and making the transcluding element
      its only child. This scheme is subject to the following
      additional constraints:

      * There must be no RDFa attributes in the transcluding element
        or its parent, except for @rel or @rev.

      * If the parent element contains a @rel or @rev, then the
        transcluding element must not, and vice versa.

      * If the transcluding element or its parent contains a @rel or
        @rev attribute, the transcluded document's <body> must not. Nor
        must it contain @property, @datatype, or @content.

      * If neither the transcluding element nor its parent contain
        @rel or @rev attributes, then the transcluded subject URI can
        go into the transcluding element's parent's @about attribute;
        otherwise it must go into @resource.

      * If the <body> of the transcluded document is a different
        subject URI from the containing document itself, then the
        parent of the transcluding element will assume the URI of the
        *transcluded document*, and refer the <body> to secondary
        processing.

      Secondary processing involves taking a look at nodes under the
      <body> of the transcluded document, particularly if there is
      only one element (and no non-whitespace text nodes). If exactly
      one child element exists under the transcluded <body>, and the
      containing element (i.e., replacement for transcluded <body>) in
      the transcluding document has not already been assigned, then
      this only-child element is a candidate, subject to constraints:

      * The element must not contain any RDFa attributes whatsoever.

      * The element must not contain an @id attribute if the <body>
        contains an @id.

      ***

      now we either want to merge the body with the parent or mint up
      a new element to enclose it.

      whether or not the transcluding tag was alone and its parent is
      a block element.

      what's in the content being transcluded? how many elements?

      only consider merging with the transcluding element's parent if
      the transcluding element is the only element child of its parent
      (whitespace-only text nodes, comments and processing
      instructions are ignored.)

      if the parent element passes this first test, we check its RDFa
      attribute situation, or rather, the union of RDFa attributes
      between it and the transcluding element (almost certainly a
      <script>). the transcluding element will invariably have the URI
      in an object attribute (href or src).

      
  -->

<xsl:template match="*" mode="test-types" name="test-types">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="types">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="in" select="''"/>

  <!-- save ourselves some butthurt -->
  <xsl:variable name="_1" select="normalize-space($types)"/>
  <xsl:variable name="_2" select="normalize-space($in)"/>
  <xsl:variable name="_3" select="concat(' ', $_2, ' ')"/>

  <xsl:if test="string-length($_1) and string-length($_2)">
    <xsl:choose>
      <xsl:when test="contains($_1, ' ')">
        <xsl:variable name="_" select="substring-before($_1, ' ')"/>
        <xsl:if test="contains($_3, concat(' ', $_, ' '))">
          <xsl:variable name="rest">
            <xsl:call-template name="test-types">
              <xsl:with-param name="base" select="$base"/>
              <xsl:with-param name="types" select="substring-after($_1, ' ')"/>
              <xsl:with-param name="in" select="$in"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="normalize-space(concat($_, ' ', $rest))"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="contains($_3, concat(' ', $_1, ' '))">
        <xsl:value-of select="$_1"/>
      </xsl:when>
    </xsl:choose>
  </xsl:if>
</xsl:template>

<xsl:template match="*" mode="relevant-types">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="types">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <!-- get all the asserted types, clip off the first type -->

  <!-- find the declaration for that type --> 
</xsl:template>

<xsl:template match="html:section[@about|@resource]">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="caller" select="/.."/>

  <xsl:variable name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="status">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="predicate" select="'http://purl.org/ontology/bibo/status'"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="class">
    <xsl:variable name="_">
      <xsl:value-of select="normalize-space(@class)"/>
      <xsl:if test="contains(concat(' ', $status, ' '), ' http://purl.org/ontology/bibo/status/draft ')">
        <xsl:text> draft</xsl:text>
      </xsl:if>
      <xsl:if test="contains(concat(' ', $status, ' '), ' https://privatealpha.com/ontology/content-inventory/1#confidential ')">
        <xsl:text> confidential</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:value-of select="normalize-space($_)"/>
  </xsl:variable>

<section>
  <xsl:if test="$class">
    <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
  </xsl:if>
  <xsl:apply-templates select="@*[name() != 'class']" mode="xc:attribute">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
  </xsl:apply-templates>

  <!-- now everything beneath -->
  <xsl:apply-templates select="*|text()">
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading + 1"/>
  </xsl:apply-templates>
</section>
</xsl:template>

<xsl:template match="svg:svg[not(ancestor::svg:svg)]" mode="xc:transclude">
  <xsl:param name="base" select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="caller" select="/.."/>

  <xsl:if test="not($caller)">
    <xsl:message terminate="yes">transclude always needs a caller!</xsl:message>
  </xsl:if>

  <xsl:variable name="parent" select="$caller/.."/>

  <xsl:choose>
    <xsl:when test="count($parent/*) = 1 and normalize-space($parent/text()) = ''">
      <xsl:element name="{name($parent)}" namespace="{namespace-uri($parent)}">
        <xsl:apply-templates select="$parent/@*" mode="xc:attribute">
          <xsl:with-param name="base">
            <xsl:apply-templates select="$parent" mode="xc:local-base"/>
          </xsl:with-param>
          <xsl:with-param name="rewrite" select="$rewrite"/>
        </xsl:apply-templates>

        <xsl:apply-templates select="." mode="svg-bp">
          <xsl:with-param name="base"          select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
        </xsl:apply-templates>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="." mode="svg-bp">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="svg:svg" mode="svg-bp">
  <xsl:param name="base" select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="caller" select="/.."/>

  <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <xsl:apply-templates select="@*[name() != 'width' and name() != 'height']" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>
    <xsl:if test="not(@viewBox)">
      <xsl:apply-templates select="@*[name() = 'width' or name() = 'height']" mode="xc:attribute">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
      </xsl:apply-templates>
    </xsl:if>

    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
    </xsl:apply-templates>
  </svg>
</xsl:template>

<!-- section/h# -->
<!--
<xsl:template match="(html:h1|html:h2|html:h3|html:h4|html:h5|html:h6)[parent::html:section]">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

<xsl:element name="{name()}">
  <xsl:apply-templates select="@*[name() != 'title']" mode="xc:attribute">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
  </xsl:apply-templates>

  <xsl:apply-templates>
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
  
</xsl:element>
  
</xsl:template>
-->

<!-- abbr and dfn -->

<xsl:template match="html:abbr[normalize-space(@title) = '']" name="ordinary-abbr">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

<xsl:variable name="titled" select="key('titled-abbr', normalize-space(.))[1]"/>
<xsl:choose>
  <xsl:when test="$titled">
    <abbr>
      <xsl:apply-templates select="@*[name() != 'title']" mode="xc:attribute">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
      </xsl:apply-templates>

      <xsl:attribute name="title">
        <xsl:value-of select="normalize-space($titled/@title)"/>
      </xsl:attribute>

      <xsl:apply-templates>
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </abbr>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="xc:html-no-op">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
    </xsl:call-template>
  </xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="html:abbr[not(ancestor::html:a)][not(descendant::html:a)][not(ancestor::html:dfn)][not(ancestor::html:*[@property][not(@content)])]">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="supplant" select="key('linked-abbr', normalize-space(.))"/>
  <!--<xsl:message>lol (<xsl:value-of select="count($supplant)"/>) this many abbrs to choose from for <xsl:value-of select="normalize-space(.)"/></xsl:message>-->
  <xsl:choose>
    <xsl:when test="$supplant[normalize-space(..) = normalize-space(current())]">
      <xsl:apply-templates select="$supplant[ancestor::html:a[1][count(node())=1]][1]/ancestor::html:a[1]">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="ordinary-abbr">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="html:dfn[not(ancestor::html:a)][not(descendant::html:a)][not(ancestor::html:abbr)][not(ancestor::html:*[@property][not(@content)])]">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="supplant" select="key('linked-dfn', normalize-space(.))"/>
  <!--<xsl:message>lol (<xsl:value-of select="count($supplant)"/>) this many dfns to choose from for <xsl:value-of select="normalize-space(.)"/></xsl:message>-->
  <xsl:choose>
    <xsl:when test="$supplant[normalize-space(..) = normalize-space(current())]">
      <xsl:apply-templates select="$supplant[ancestor::html:a[1][count(node())=1]][1]/ancestor::html:a[1]">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="xc:html-no-op">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="html:a[@href][normalize-space(.) = '']">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="href">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="uri" select="@href"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="types">
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$href"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
    <xsl:text> </xsl:text>
  </xsl:variable>

  <xsl:message><xsl:value-of select="$href"/> has types <xsl:value-of select="$types"/></xsl:message>
 
  <a>
    <xsl:apply-templates select="@*" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>

    <!-- who knows, there may be elements -->
    <xsl:apply-templates select="*">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading + 1"/>
    </xsl:apply-templates>

    <xsl:choose>
      <xsl:when test="contains($types, ' http://www.w3.org/ns/oa#Annotation ')">
        <xsl:text>[Untitled Note]</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>[Untitled]</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </a>

</xsl:template>


<!-- catch-all template for text -->

<xsl:template match="text()[not(ancestor::html:pre|ancestor::html:code|ancestor::html:kbd|ancestor::html:samp|ancestor::html:script)]">
  <xsl:variable name="apos">'</xsl:variable>
  <xsl:value-of select="translate(., string($apos), '&#x2019;')"/>
</xsl:template>


</xsl:stylesheet>
