<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text" encoding="utf-8"/>
  <xsl:template match="text()"/>
  <xsl:template match="//MedlineCitation">
<xsl:if test="not(Article/Language) or Article/Language='eng'">
        <xsl:text>D http://www.ncbi.nlm.nih.gov/pubmed/</xsl:text>
	<xsl:value-of select="PMID"/>
	<xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(Article/ArticleTitle)"/>
        <xsl:text>
EOL
</xsl:text>
        <xsl:for-each select=".//AbstractText">
	<xsl:text>text </xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
         <xsl:text>
</xsl:text>
</xsl:for-each>
<xsl:if test="normalize-space(Article/Journal)">
	<xsl:text>journal </xsl:text>
        <xsl:value-of select="normalize-space(Article/Journal/Title)"/>
         <xsl:text>
</xsl:text>
</xsl:if>
        <xsl:for-each select="MeshHeadingList/MeshHeading">
          <xsl:text>mesh </xsl:text>
          <xsl:value-of select="normalize-space(DescriptorName)"/>
          <xsl:text>
</xsl:text>
          <xsl:for-each select="QualifierName">
          <xsl:text>mesh </xsl:text>
          <xsl:value-of select="normalize-space(../DescriptorName)"/>
          <xsl:text> :: </xsl:text>
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text>
</xsl:text>
	  </xsl:for-each>
        </xsl:for-each>
        <xsl:for-each select="ChemicalList/Chemical/NameOfSubstance">
          <xsl:text>chemical </xsl:text>
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
        <xsl:for-each select="Article/AuthorList/Author">
          <xsl:text>author </xsl:text>
          <xsl:value-of select="normalize-space(LastName)"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="normalize-space(Initials)"/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
        <xsl:for-each select="KeywordList/Keyword">
          <xsl:text>key</xsl:text>
          <xsl:value-of select="normalize-space(../@Owner)"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
        <xsl:for-each select=".//PubDate">
          <xsl:text>pubdate </xsl:text>
	  <xsl:if test="Month">
          <xsl:value-of select="normalize-space(Month)"/>
          <xsl:text> </xsl:text>
	  </xsl:if>
          <xsl:value-of select="normalize-space(Year)"/>
          <xsl:text>
</xsl:text>
        </xsl:for-each>
        <xsl:text>EOD
</xsl:text>
</xsl:if>
  </xsl:template>
</xsl:stylesheet>

