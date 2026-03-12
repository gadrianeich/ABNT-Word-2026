<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/document">
    <document-formatado>
      <xsl:apply-templates/>
    </document-formatado>
  </xsl:template>
  <xsl:template match="titulo">
    <titulo style="font-size:16pt; font-weight:bold; text-align:center; text-transform:uppercase; font-family:'Times New Roman'">
      <xsl:value-of select="."/>
    </titulo>
  </xsl:template>
  <xsl:template match="subtitulo">
    <subtitulo style="font-size:14pt; font-weight:bold; text-align:left; font-family:'Times New Roman'">
      <xsl:value-of select="."/>
    </subtitulo>
  </xsl:template>
  <xsl:template match="paragrafo">
    <paragrafo style="font-size:12pt; line-height:1.5; text-align:justify; font-family:'Times New Roman'">
      <xsl:value-of select="."/>
    </paragrafo>
  </xsl:template>
  <xsl:template match="citação">
    <citacao style="margin-left:4cm; font-size:10pt; font-style:italic;">
      <xsl:value-of select="."/>
    </citacao>
  </xsl:template>
  <xsl:template match="referencia">
    <referencia style="font-size:10pt;">
      <xsl:value-of select="."/>
    </referencia>
  </xsl:template>
</xsl:stylesheet>