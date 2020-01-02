<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:eg="http://example.org/ns"
  exclude-result-prefixes="xs eg">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>

    <xsl:function name="eg:func" visibility="public">
        <xsl:param name="str"  as="xs:string?"/>
        <function-result>
            <xsl:if test="exists($str)"><str><xsl:value-of select="$str"/></str></xsl:if>
        </function-result>
    </xsl:function>

    <xsl:function name="eg:int" visibility="public" as="xs:integer">
        <xsl:sequence select="1"/>
    </xsl:function>
</xsl:stylesheet>