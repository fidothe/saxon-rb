<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0">
    
    <xsl:template match="root">
        <xsl:apply-templates select="*"/>
    </xsl:template>
    
    <xsl:template match="child[parent::root]">
        <out/>
    </xsl:template>
    
    <xsl:template match="child[parent::*]">
        <pout/>
    </xsl:template>
</xsl:stylesheet>