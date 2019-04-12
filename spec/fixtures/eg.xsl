<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <xsl:param name="testparam" select="'default'"/>
    <xsl:template name="by-template">
        <template><xsl:if test="$testparam != 'default'"><xsl:value-of select="$testparam"/></xsl:if></template>
    </xsl:template>
    <xsl:template match="input">
        <output><xsl:if test="$testparam != 'default'"><xsl:value-of select="$testparam"/></xsl:if></output>
    </xsl:template>
    <xsl:template match="input" mode="test">
        <test-output/>
    </xsl:template>
    <xsl:template match="output">
        <piped/>
    </xsl:template>
</xsl:stylesheet>