<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:eg="http://example.org/eg"
    exclude-result-prefixes="xs math"
    version="3.0">

    <xsl:template match="child">
        <xsl:sequence select="eg:bound-to-fail(.)"/>
    </xsl:template>
    
    <xsl:function name="eg:bound-to-fail" as="element()+">
        <xsl:param name="node"/>

        <xsl:analyze-string select="$node" regex="bothersome">
            <xsl:matching-substring><el/></xsl:matching-substring>
            <xsl:non-matching-substring/>
        </xsl:analyze-string>
    </xsl:function>
</xsl:stylesheet>