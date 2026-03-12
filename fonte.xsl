<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="fonte">
    <fonte style="font-family:'Arial'; font-size:10pt; color:#333;">
      <xsl:value-of select="."/>
    </fonte>
  </xsl:template>
</xsl:stylesheet>