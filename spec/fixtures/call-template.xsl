<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:eg="http://example.org/ns"
  exclude-result-prefixes="xs eg">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>

    <xsl:template name="root">
        <xsl:param name="template-param" select="()" as="xs:string?"/>
        <xsl:param name="template-tunnel-param" tunnel="yes" select="()" as="xs:string?"/>
        <root-template>
            <xsl:if test="exists($template-param)"><t><xsl:value-of select="$template-param"/></t></xsl:if>
            <xsl:if test="exists($template-tunnel-param)"><tt><xsl:value-of select="$template-tunnel-param"/></tt></xsl:if>
        </root-template>
    </xsl:template>

    <xsl:template name="eg:root">
        <xsl:param name="template-param" select="()" as="xs:string?"/>
        <xsl:param name="template-tunnel-param" tunnel="yes" select="()" as="xs:string?"/>
        <ns-root-template>
            <xsl:if test="exists($template-param)"><t><xsl:value-of select="$template-param"/></t></xsl:if>
            <xsl:if test="exists($template-tunnel-param)"><tt><xsl:value-of select="$template-tunnel-param"/></tt></xsl:if>
        </ns-root-template>
    </xsl:template>

    <xsl:template name="context">
        <context><xsl:value-of select="@value"/></context>
    </xsl:template>
    
    <xsl:template name="xsl:initial-template">
        <xsl:param name="template-param" select="()" as="xs:string?"/>
        <xsl:param name="template-tunnel-param" tunnel="yes" select="()" as="xs:string?"/>
        <default-template>
            <xsl:if test="exists($template-param)"><t><xsl:value-of select="$template-param"/></t></xsl:if>
            <xsl:if test="exists($template-tunnel-param)"><tt><xsl:value-of select="$template-tunnel-param"/></tt></xsl:if>
        </default-template>
    </xsl:template>
</xsl:stylesheet>