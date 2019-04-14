<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:eg="http://example.org/#ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="eg xs"
    version="3.0">
    
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    
    <xsl:param name="static-param" static="yes" as="xs:string" select="'static default'"/>
    <xsl:param name="global-param" as="xs:string">global default</xsl:param>
    <xsl:param name="eg:qname-global-param" select="1" as="xs:integer"/>

    <xsl:template match="input">
        <xsl:param name="template-param">template default</xsl:param>
        <xsl:param name="template-tunnel-param" tunnel="yes">template tunnel default</xsl:param>
        
        <output>
            <static-param><xsl:value-of select="$static-param"/></static-param>
            <global-param><xsl:value-of select="$global-param"/></global-param>
            <qname-global-param><xsl:value-of select="$eg:qname-global-param"/></qname-global-param>
            <template-param><xsl:value-of select="$template-param"/></template-param>
            <template-tunnel-param><xsl:value-of select="$template-tunnel-param"/></template-tunnel-param>
        </output>
    </xsl:template>

    <xsl:template name="named-template">
        <xsl:param name="template-param">template default</xsl:param>
        <xsl:param name="template-tunnel-param" tunnel="yes">template tunnel default</xsl:param>
        
        <output>
            <static-param><xsl:value-of select="$static-param"/></static-param>
            <global-param><xsl:value-of select="$global-param"/></global-param>
            <qname-global-param><xsl:value-of select="$eg:qname-global-param"/></qname-global-param>
            <template-param><xsl:value-of select="$template-param"/></template-param>
            <template-tunnel-param><xsl:value-of select="$template-tunnel-param"/></template-tunnel-param>
        </output>
    </xsl:template>
</xsl:stylesheet>
