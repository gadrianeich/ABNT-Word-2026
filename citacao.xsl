<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="citação">
    <citacao style="font-family:'Times New Roman'; font-size:10pt; font-style:italic; margin-left:4cm;">
      <xsl:value-of select="."/>
    </citacao>
  </xsl:template>
</xsl:stylesheet>