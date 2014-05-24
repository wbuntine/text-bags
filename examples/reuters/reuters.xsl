<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text" encoding="iso-8859-1"/>
  <xsl:template match="text()"/>
  <xsl:template match="//newsitem">
        <xsl:text>D Reuters/</xsl:text>
	<xsl:value-of select="@itemid"/>
        <xsl:text>newsML.xml 0</xsl:text>
	<xsl:value-of select="@itemid"/>
	<xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(title)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(dateline)"/>
        <xsl:text>
EOL
</xsl:text>
	<xsl:text>text </xsl:text>
        <xsl:value-of select="normalize-space(headline)"/>
         <xsl:text>
</xsl:text>
	<xsl:text>text </xsl:text>
        <xsl:value-of select="normalize-space(text)"/>
         <xsl:text>
</xsl:text>
        <xsl:for-each select="metadata/codes/code">
          <xsl:text>code </xsl:text>
          <xsl:value-of select="normalize-space(@code)"/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
	<xsl:text>location </xsl:text>
        <xsl:value-of select="normalize-space(metadata/dc[@element='dc.creator.location']/@value)"/>
         <xsl:text>
</xsl:text>
	<xsl:text>country </xsl:text>
        <xsl:value-of select="normalize-space(metadata/dc[@element='dc.creator.location.country.name']/@value)"/>
         <xsl:text>
</xsl:text>
        <xsl:text>EOD
</xsl:text>
  </xsl:template>
</xsl:stylesheet>

