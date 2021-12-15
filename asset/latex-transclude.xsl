<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:uri="http://xsltsl.org/uri"
                xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
                xmlns:z="urn:x-dummy:data"
                exclude-result-prefixes="z uri xc">

<xsl:import href="/asset/rdfa"/>
<xsl:import href="/asset/transclude"/>
<xsl:import href="/asset/generate-latex"/>

<xsl:output method="text" media-type="text/x-tex" encoding="utf-8"/>

<xsl:template match="@href" mode="href-text">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>

  <xsl:call-template name="uri:resolve-uri">
    <xsl:with-param name="uri" select="normalize-space(.)"/>
    <xsl:with-param name="base" select="$base"/>
  </xsl:call-template>

</xsl:template>

</xsl:stylesheet>
