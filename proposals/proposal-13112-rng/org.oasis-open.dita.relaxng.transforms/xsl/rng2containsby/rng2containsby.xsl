<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:rnga="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:str="http://local/stringfunctions"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  exclude-result-prefixes="xs xd rng rnga relpath str ditaarch rngfunc"
  version="2.0">

  <xsl:import href="../lib/relpath_util.xsl" />

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>RNG to Contains/Contained By Table Generator</xd:p>
      <xd:p>This transform takes as input RNG-format DITA document type
        shells and produces a set of contains and contained-by tables,
        one for each unique element type. All the tables are output in a
        single topic for use in the DITA specification.
      </xd:p>
    </xd:desc>
  </xd:doc>

  <!--
    <!DOCTYPE dita PUBLIC "-//OASIS//DTD DITA Composite//EN" "ditabase.dtd">
    -->
  <xsl:output 
    method="xml"
    indent="yes"
    doctype-public="-//OASIS//DTD DITA Composite//EN"
    doctype-system="ditabase.dtd"
  />
  <xsl:output name="grammar"
    method="xml"
    indent="yes"
  />

  <xsl:param name="debug" as="xs:string" select="'false'"/>
  
  <xsl:variable name="doDebug" as="xs:boolean" select="$debug = 'true'" />

  <xsl:strip-space elements="*"/>
  
  <xsl:key name="patternsByName" match="rng:define" use="@name" />
  <xsl:key name="attlistIndex" match="rng:element" use="rng:ref[ends-with(@name, '.attlist')]/@name" />
  
  <xsl:include href="rng-utils.xsl"/>
  <xsl:include href="rng-merge-grammar.xsl"/>
  <xsl:include href="rng-normalize-grammar.xsl"/>
  <xsl:include href="rng-make-alpha-nav-topics.xsl"/>
  <xsl:include href="rng-make-tables.xsl"/>

  <xsl:template match="/">
    <!-- Process:
      
         0. Merge the grammar documents
         
         1. Normalize the content models
      
         2. Gather the set of unique element types.
         
         3. For each element type, calculate its content and
            containment.
            
     -->
    <xsl:message> + [INFO] Merging grammar...</xsl:message>
    <xsl:variable name="mergedGrammar" as="document-node()">
      <xsl:document>
        <xsl:apply-templates select="." mode="merge-grammar">
          <xsl:with-param name="origDoc" as="document-node()" select="root(.)" tunnel="yes"/>
        </xsl:apply-templates> 
      </xsl:document>
    </xsl:variable>
    
    <xsl:if test="$doDebug">
      <xsl:variable name="mergedUri" as="xs:string"
        select="relpath:newFile(relpath:getParent(document-uri(.)), concat(relpath:getName(document-uri(.)), '-merged.rng'))"
      />
      <xsl:message> + [DEBUG] Writing merged grammar to "<xsl:value-of select="$mergedUri"/>"</xsl:message>
      <xsl:result-document href="{$mergedUri}" format="grammar">
        <xsl:sequence select="$mergedGrammar"/>
      </xsl:result-document>
    </xsl:if>
    
    <xsl:message> + [INFO] Normalizing grammar...</xsl:message>
    <xsl:variable name="normalizedGrammar" as="document-node()">
      <xsl:document>
        <xsl:apply-templates select="$mergedGrammar" mode="normalize-grammar">
          <xsl:with-param name="origDoc" as="document-node()" select="root(.)" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:document>
    </xsl:variable>
    
    <xsl:if test="$doDebug">
      <xsl:variable name="normalizedUri" as="xs:string"
        select="relpath:newFile(relpath:getParent(document-uri(.)), concat(relpath:getName(document-uri(.)), '-normalized.rng'))"
      />
      <xsl:message> + [DEBUG] Writing normalized grammar to "<xsl:value-of select="$normalizedUri"/>"</xsl:message>
      <xsl:result-document href="{$normalizedUri}" format="grammar">
        <xsl:sequence select="$normalizedGrammar"/>
      </xsl:result-document>
    </xsl:if>
    
    <xsl:message> + [INFO] Generating contains-by tables...</xsl:message>
    <dita>
      <xsl:apply-templates mode="make-alpha-nav-topics" select="$normalizedGrammar"/>
      <xsl:apply-templates mode="make-tables" select="$normalizedGrammar"/>
    </dita>
    <xsl:message> + [INFO] Done.</xsl:message>
    
  </xsl:template>
  
  <xsl:template mode="#default" match="text()"/>

</xsl:stylesheet>