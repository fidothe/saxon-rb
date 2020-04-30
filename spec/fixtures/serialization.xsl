<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:output indent="no" omit-xml-declaration="yes" use-character-maps="silly"/>
    <xsl:character-map name="silly">
        <xsl:output-character character="a" string="b"/>
    </xsl:character-map>
</xsl:stylesheet>