<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <xsl:param name="global-param" select="()" as="xs:string?"/>
    <xsl:param name="static-param" static="yes" as="xs:string?" select="()"/>

    <xsl:template match="root">
        <xsl:param name="template-param" select="()" as="xs:string?"/>
        <xsl:param name="template-tunnel-param" tunnel="yes" select="()" as="xs:string?"/>
        <output>
            <xsl:if test="exists($static-param)"><s><xsl:value-of select="$static-param"/></s></xsl:if>
            <xsl:if test="exists($global-param)"><g><xsl:value-of select="$global-param"/></g></xsl:if>
            <xsl:if test="exists($template-param)"><t><xsl:value-of select="$template-param"/></t></xsl:if>
            <xsl:if test="exists($template-tunnel-param)"><tt><xsl:value-of select="$template-tunnel-param"/></tt></xsl:if>
        </output>
    </xsl:template>

    <xsl:template match="root" mode="test">
        <mode-output/>
    </xsl:template>

    <xsl:template match="child">
        <child-output/>
    </xsl:template>
</xsl:stylesheet>