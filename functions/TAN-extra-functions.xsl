<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="#all" version="2.0">

   <!-- Functions that are not central to validating TAN files, but could be helpful in creating, editing, or reusing them -->

   <!-- node manipulation -->
   <xsl:function name="tan:group-elements-by-children" as="element()*">
      <!-- One-parameter version of the fuller one below.  -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:copy-of select="tan:group-elements-by-children($elements-to-group, ())"/>
   </xsl:function>
   <xsl:function name="tan:group-elements-by-children" as="element()*">
      <!-- Input: a sequence of elements and an optional string representing the name of children in the elements -->
      <!-- Output: the same elements, but grouped in <group> according to whether the text contents of the child elements specified are equal -->
      <!-- Transitivity is assumed. If suppose elements X, Y, and Z have children values A and B; B and C; and C and D, respectively. All three elements will be grouped, even though Y and Z do not share children values directly.  -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:param name="name-of-children-to-group-by" as="xs:string?"/>
      <xsl:copy-of
         select="tan:group-elements-by-children($elements-to-group, $name-of-children-to-group-by, ())"
      />
   </xsl:function>
   <xsl:function name="tan:group-elements-by-children" as="element()*">
      <!-- Fuller, looped version of the function. The one most frequently used will be the 2-parameter version, discussed above. -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:param name="name-of-children-to-group-by" as="xs:string?"/>
      <xsl:param name="groups-so-far" as="element()*"/>
      <xsl:variable name="all-children" as="xs:boolean"
         select="string-length($name-of-children-to-group-by) lt 1"/>
      <xsl:variable name="this-element-to-group" select="$elements-to-group[1]"/>
      <xsl:choose>
         <xsl:when test="not(exists($this-element-to-group))">
            <xsl:for-each select="$groups-so-far">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="n" select="position()"/>
                  <xsl:copy-of select="node()"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="grouping-key"
               select="
                  $this-element-to-group/*[if ($all-children) then
                     true()
                  else
                     name() = $name-of-children-to-group-by]"/>
            <xsl:variable name="matching-groups"
               select="
                  $groups-so-far[*/*[if ($all-children) then
                     true()
                  else
                     name() = $name-of-children-to-group-by and . = $grouping-key]]"/>
            <xsl:variable name="non-matching-groups"
               select="
                  $groups-so-far[not(*/*[if ($all-children) then
                     true()
                  else
                     name() = $name-of-children-to-group-by and . = $grouping-key])]"/>
            <xsl:variable name="new-groups" as="element()*">
               <xsl:copy-of select="$non-matching-groups"/>
               <group grouping-key="{$name-of-children-to-group-by}">
                  <xsl:copy-of select="$matching-groups/*"/>
                  <xsl:copy-of select="$this-element-to-group"/>
               </group>
            </xsl:variable>
            <xsl:copy-of
               select="tan:group-elements-by-children($elements-to-group[position() gt 1], $name-of-children-to-group-by, $new-groups)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>



   <!-- bibliographies -->
   <xsl:param name="bibliography-words-to-ignore" as="xs:string*"
      select="('university', 'press', 'publication')"/>
   <xsl:function name="tan:possible-bibliography-id" as="xs:string">
      <!-- Input: a string with a bibliographic entry -->
      <!-- Output: unique values of the two longest words and the first numeral that looks like a date -->
      <!-- When working with bibliographical data, it is next to impossible to rely upon an exact match to tell whether two citations are for the same item -->
      <!-- Many times, however, the longest word or two, plus the four-digit date, are good ways to try to find matches. -->
      <xsl:param name="bibl-cit" as="xs:string"/>
      <xsl:variable name="this-citation-dates" as="xs:string*">
         <xsl:analyze-string select="$bibl-cit" regex="^\d\d\d\d\D|\D\d\d\d\d\D|\D\d\d\d\d$">
            <xsl:matching-substring>
               <xsl:value-of select="replace(., '\D', '')"/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="this-citation-longest-words" as="xs:string*">
         <xsl:for-each select="tokenize($bibl-cit, '\W+')">
            <xsl:sort select="string-length(.)" order="descending"/>
            <xsl:if test="not(lower-case(.) = $bibliography-words-to-ignore)">
               <xsl:value-of select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of
         select="string-join(distinct-values(($this-citation-longest-words[position() lt 3], $this-citation-dates[1])), ' ')"
      />
   </xsl:function>

</xsl:stylesheet>
