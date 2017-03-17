<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://docbook.org/ns/docbook" xmlns:docbook="http://docbook.org/ns/docbook"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:saxon="http://icl.com/saxon"
   xmlns:lxslt="http://xml.apache.org/xslt" xmlns:redirect="http://xml.apache.org/xalan/redirect"
   xmlns:exsl="http://exslt.org/common" xmlns:doc="http://nwalsh.com/xsl/documentation/1.0"
   xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xpath-default-namespace="http://docbook.org/ns/docbook"
   extension-element-prefixes="saxon redirect lxslt exsl" exclude-result-prefixes="#all"
   version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b> March 2017</xd:p>
         <xd:p>The input xml file to this stylesheet is immaterial. The stylesheet will transform
            all the TAN schema files into a series of Docbook inclusions for the TAN guidelines,
            documenting the structural rules, the validation rules, the schematron quick
            fixes.</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:output method="xml" indent="no"/>

   <xsl:include href="../../functions/incl/TAN-core-functions.xsl"/>
   <xsl:include href="../../functions/incl/TAN-schema-functions.xsl"/>
   <xsl:include href="../get%20inclusions/rng-to-text.xsl"/>
   <xsl:include href="../get%20inclusions/tan-snippet-to-docbook.xsl"/>
   <xsl:include href="../get%20inclusions/tan-keywords-to-docbook.xsl"/>
   <xsl:include href="../get%20inclusions/XSLT%20analysis.xsl"/>

   <xsl:param name="indent-value" select="3"/>
   <xsl:variable name="indent"
      select="
         string-join(for $i in (1 to $indent-value)
         return
            ' ')"/>
   <xsl:param name="max-examples" select="4"/>
   <xsl:param name="qty-contextual-siblings" select="1"/>
   <xsl:param name="qty-contextual-children" select="3"/>
   <xsl:param name="max-example-size" select="2000"/>

   <xsl:variable name="ex-collection"
      select="
         collection('../examples/?select=*.xml;recurse=yes'),
         collection('../TAN-key/?select=*.xml;recurse=yes')"/>
   <xsl:variable name="fn-collection" select="collection('../functions/?select=*.xsl;recurse=yes')"/>
   <xsl:variable name="keyword-collection"
      select="collection('../TAN-key/?select=*key.xml;recurse=yes')"/>
   <xsl:variable name="elements-excl-TEI" select="$rng-collection-without-TEI//rng:element[@name]"/>
   <xsl:variable name="attributes-excl-TEI"
      select="$rng-collection-without-TEI//rng:attribute[@name]"/>
   <xsl:variable name="distinct-element-names" select="distinct-values($elements-excl-TEI/@name)"/>
   <xsl:variable name="distinct-attribute-names"
      select="distinct-values($attributes-excl-TEI/@name)"/>

   <xsl:variable name="function-library-keys" select="$all-functions/xsl:stylesheet/xsl:key"/>
   <xsl:variable name="function-library-functions"
      select="$all-functions/xsl:stylesheet/xsl:function"/>
   <xsl:variable name="function-library-templates"
      select="$all-functions/xsl:stylesheet/xsl:template"/>
   <xsl:variable name="function-library-template-names-and-modes"
      select="
         for $i in $function-library-templates/(@name, @mode)
         return
            tokenize($i, '\s+')"/>
   <xsl:variable name="function-library-variables"
      select="$all-functions/xsl:stylesheet/xsl:variable"/>

   <xsl:variable name="lf" select="'&#xA;'"/>
   <xsl:variable name="lt" select="'&lt;'"/>
   <xsl:variable name="ellipses" select="'.........&#xA;'"/>

   <xsl:variable name="sequence-of-sections" as="element()">
      <!-- Depicts the structure and sequence the documentation should take. In practice, the chapters that use this variable flatten the hierarchy -->
      <sec n="TAN-core">
         <sec n="TAN-core-errors"/>
         <sec n="TAN-class-1">
            <sec n="TAN-T"/>
         </sec>
         <sec n="TAN-class-1-errors"/>
         <sec n="TAN-class-2">
            <sec n="TAN-A-div"/>
            <sec n="TAN-A-div-errors"/>
            <sec n="TAN-A-tok"/>
            <sec n="TAN-LM-core"/>
            <sec n="TAN-LM-lang"/>
         </sec>
         <sec n="TAN-class-2-errors"/>
         <sec n="TAN-class-1-and-2"/>
         <sec n="TAN-class-3">
            <sec n="TAN-key"/>
            <sec n="TAN-mor"/>
            <sec n="TAN-c"/>
            <sec n="TAN-c-core"/>
         </sec>
         <sec n="TAN-class-2-and-3"/>
         <sec n="diff-for-xslt2"/>
         <sec n="TAN-schema"/>
      </sec>
   </xsl:variable>

   <xsl:function name="tan:prep-string-for-docbook" as="item()*">
      <xsl:param name="text" as="xs:string*"/>
      <xsl:variable name="pass-1" as="item()*">
         <!-- This <analyze-string> regular expression looks for <ELEMENT> ~PATTERN @ATTRIBUTE key('KEY') tan:FUNCTION() $VARIABLE as endpoints -->
         <!-- It also looks for, but does not treat as an endpoint, {template (mode|named) TEMPLATE}, to at least put it inside of <code> -->
         <!-- We coin initial ~ as representing a pattern, similar to the @ prefix to signal an attribute -->
         <xsl:for-each select="$text">
            <xsl:analyze-string select="."
               regex="{$lt || '([-:\w]+)>|[~@]([-:\w]+)|key\('||$apos||'([-\w]+)'||$apos||'\)|tan:([-\w]+)\(\)|\$([-\w]+)|[Ŧŧ] ([-#\w]+)'}">
               <xsl:matching-substring>
                  <xsl:variable name="linkend" as="xs:string?">
                     <!-- This variable captures only those patterns that have destination points in the documentation -->
                     <xsl:choose>
                        <xsl:when test="matches(., '^' || $lt)">
                           <xsl:value-of select="'element-' || regex-group(1)"/>
                        </xsl:when>
                        <xsl:when test="matches(., '^@')">
                           <xsl:value-of select="'attribute-' || regex-group(2)"/>
                        </xsl:when>
                        <xsl:when test="matches(., '^~')">
                           <xsl:value-of select="'define-' || regex-group(2)"/>
                        </xsl:when>
                        <xsl:when
                           test="matches(., '^key') and regex-group(3) = $function-library-keys/@name">
                           <xsl:value-of select="'key-' || regex-group(3)"/>
                        </xsl:when>
                        <xsl:when
                           test="matches(., '^tan:[-\w]+\(\)') and ('tan:' || regex-group(4)) = $function-library-functions/@name">
                           <xsl:value-of select="'function-' || regex-group(4)"/>
                        </xsl:when>
                        <xsl:when
                           test="matches(., '^\$[-\w]+') and regex-group(5) = $function-library-variables/@name">
                           <xsl:value-of select="'variable-' || regex-group(5)"/>
                        </xsl:when>
                        <xsl:when
                           test="matches(., '^[Ŧŧ]') and regex-group(6) = $function-library-template-names-and-modes">
                           <xsl:value-of select="'template-' || regex-group(6)"/>
                        </xsl:when>
                     </xsl:choose>
                  </xsl:variable>
                  <code>
                     <xsl:choose>
                        <xsl:when test="exists($linkend)">
                           <link linkend="{replace($linkend,'[:#]','')}">
                              <xsl:value-of select="."/>
                           </link>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:value-of select="."/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </code>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:analyze-string select="." regex="main\.xml#[-_\w]+|iris\.xml|https?://\S+">
                     <xsl:matching-substring>
                        <xsl:choose>
                           <xsl:when test="starts-with(., 'main')">
                              <xref linkend="{replace(.,'main\.xml#','')}"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <link xlink:href="{.}">
                                 <xsl:value-of select="."/>
                              </link>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of select="$pass-1"/>
   </xsl:function>

   <!--<xsl:variable name="component-syntax" as="element()">
      <syntax>
         <component type="attribute" syntax="@name" string-matching-pattern="@([-\w]+)"
            xpath-matching-pattern="@([-\w]+)"/>
         <component type="element" syntax="&lt;name>" string-matching-pattern="&lt;([-:\w]+)>" xpath-matching-pattern="&lt;([^>]+)>"/>
         <component type="pattern define" syntax="~name" string-matching-pattern="~([-\w]+)"/>
         <component type="key xsl:key" syntax="⚿ name')" string-matching-pattern="⚿ ?([-\w]+)" xpath-matching-pattern="key\(.([-\w]+)"/>
         <component type="function xsl:function" syntax="name()"
            string-matching-pattern="([-:\w]+)\([^\)]*\)" xpath-matching-pattern="(tan:[-\w]+)\([^\)]*\)"/>
         <component type="variable xsl:variable" syntax="$name" string-matching-pattern="\$([-\w]+)" xpath-matching-pattern="\$([-\w]+)"/>
         <component type="template xsl:template" syntax="Ŧ name" string-matching-pattern="Ŧ ([-\w]+)"/>
         <component type="template xsl:template" mode="true" syntax="ŧ name"
            string-matching-pattern="ŧ ([-w+])"/>
         <component type="error" syntax="!!name" string-matching-pattern="!!([-\w]+)" xpath-matching-pattern="tan:error\(.(\w)+"/>
      </syntax>
   </xsl:variable>-->

   <xsl:function name="tan:component-comments-to-docbook" as="element()*">
      <!-- Input: one or more XSLT elements -->
      <!-- Output: one docbook <para> per comment -->
      <xsl:param name="xslt-elements" as="element()*"/>
      <xsl:for-each select="$xslt-elements/comment()[not(preceding-sibling::*)]">
         <xsl:for-each select="tokenize(., '\n')">
            <para>
               <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
            </para>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:component-dependees-to-docbook" as="element()*">
      <!-- Input: one or more XSLT elements -->
      <!-- Output: one docbook <para> per type listing other components that depend upon the input component -->
      <xsl:param name="xslt-element" as="element()?"/>
      <xsl:variable name="this-type-of-component" select="name($xslt-element)"/>
      <xsl:variable name="what-depends-on-this"
         select="tan:xslt-dependencies($xslt-element/(@name, @mode)[1], $this-type-of-component, exists($xslt-element/@mode), $all-functions)[name() = ('xsl:function', 'xsl:variable', 'xsl:template', 'xsl:key')]"
      />
      <xsl:for-each-group select="$what-depends-on-this" group-by="name()">
         <xsl:sort select="name()" order="descending"/>
         <xsl:variable name="component-type" select="current-grouping-key()"/>
         <para>Used by <xsl:value-of select="replace(current-grouping-key(), 'xsl:', '')"/>
            <xsl:for-each select="current-group()">
               <xsl:text> </xsl:text>
               <xsl:copy-of
                  select="tan:prep-string-for-docbook(tan:string-representation-of-component((@name, @mode)[1], $component-type, exists(@mode)))"
               />
            </xsl:for-each>
         </para>
      </xsl:for-each-group>
      <xsl:if test="not(exists($what-depends-on-this))">
         <para>No variables, keys, functions, or named templates depend upon this <xsl:value-of
               select="$this-type-of-component"/>.</para>
      </xsl:if>
   </xsl:function>
   <xsl:function name="tan:component-dependencies-to-docbook" as="element()*">
      <!-- Input: one or more XSLT elements -->
      <!-- Output: one docbook <para> per type listing other components upon which the input component depends -->
      <xsl:param name="xslt-elements" as="element()*"/>
      <xsl:variable name="what-this-depends-on-pass-1" as="item()*">
         <xsl:copy-of
            select="
               for $i in $xslt-elements//@*
               return
                  tan:prep-string-for-docbook($i)"/>
         <xsl:copy-of
            select="
               for $j in $xslt-elements//xsl:call-template
               return
                  tan:prep-string-for-docbook(tan:string-representation-of-component($j/@name, 'template'))"/>
         <xsl:copy-of
            select="
               for $k in $xslt-elements//xsl:apply-templates
               return
                  tan:prep-string-for-docbook(tan:string-representation-of-component($k/@mode, 'template', true()))"
         />
      </xsl:variable>
      <xsl:variable name="what-this-depends-on-pass-2"
         select="$what-this-depends-on-pass-1/descendant-or-self::docbook:code[docbook:link[not(matches(@linkend, '^attribute-'))]]"/>
      <xsl:variable name="what-this-depends-on" as="element()*">
         <xsl:for-each select="$what-this-depends-on-pass-2">
            <xsl:variable name="pos" select="position()"/>
            <xsl:choose>
               <xsl:when
                  test="
                     $pos = 1 or not(some $i in (1 to $pos - 1)
                        satisfies deep-equal(., $what-this-depends-on-pass-2[$i]))">
                  <xsl:copy-of select="."/>
               </xsl:when>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:if test="exists($what-this-depends-on)">
         <para>Relies upon the results of <xsl:copy-of select="$what-this-depends-on"/></para>
      </xsl:if>
   </xsl:function>

   <xsl:template match="*" mode="errors-to-docbook">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template match="tan:error" mode="errors-to-docbook">
      <xsl:variable name="affected-attributes"
         select="
            for $i in ancestor-or-self::*/@affects-attribute
            return
               tokenize($i, '\s+')"/>
      <xsl:variable name="affected-elements"
         select="
            for $i in ancestor-or-self::*/@affects-element
            return
               tokenize($i, '\s+')"/>
      <section>
         <title>Error <code>[<xsl:value-of select="@xml:id"/>]</code></title>
         <xsl:apply-templates mode="#current"/>
      </section>
      <para>Affects: <xsl:copy-of
            select="tan:prep-string-for-docbook(tan:string-representation-of-component($affected-attributes, 'attribute'))"/>
         <xsl:copy-of
            select="tan:prep-string-for-docbook(tan:string-representation-of-component($affected-elements, 'element'))"
         /></para>
   </xsl:template>
   <xsl:template match="tan:rule" mode="errors-to-docbook">
      <para/>
   </xsl:template>

   <xsl:template match="/*">
      <xsl:result-document href="../../guidelines/inclusions/elements-attributes-and-patterns.xml">
         <chapter version="5.0" xml:id="elements-attributes-and-patterns">
            <title>TAN patterns, elements, and attributes defined</title>
            <para>
               <xsl:value-of
                  select="'The ' || count($distinct-element-names) || ' elements and ' || count($distinct-attribute-names) || ' attributes defined in TAN, excluding TEI, are the following::'"
               />
            </para>
            <para>
               <xsl:for-each-group select="($attributes-excl-TEI, $elements-excl-TEI)"
                  group-by="name() || ' ' || @name">
                  <xsl:sort select="lower-case(@name)"/>
                  <xsl:variable name="node-type-and-name"
                     select="tokenize(current-grouping-key(), '\s+')"/>
                  <xsl:copy-of
                     select="tan:prep-string-for-docbook(tan:string-representation-of-component($node-type-and-name[2], $node-type-and-name[1]))"/>
                  <xsl:text> </xsl:text>
               </xsl:for-each-group>
            </para>
            <xsl:for-each
               select="$rng-collection-without-TEI[tan:cfn(.) = $sequence-of-sections/descendant-or-self::*/@n]">
               <xsl:sort>
                  <xsl:variable name="this-cfn" select="tan:cfn(.)"/>
                  <xsl:copy-of
                     select="count($sequence-of-sections//*[@n = $this-cfn]/(preceding::*, ancestor-or-self::*))"
                  />
               </xsl:sort>
               <!--<xsl:sort select="index-of($sequence-of-sections, tan:cfn(.))"/>-->
               <xsl:variable name="this-rng" select="."/>
               <!--<xsl:variable name="this-cfn" select="tan:cfn(.)"/>-->
               <xsl:variable name="this-name" select="replace(tan:cfn(.), 'LM-core', 'LM')"/>
               <section>
                  <title>
                     <xsl:value-of select="$this-name || ' elements and attributes summarized'"/>
                  </title>
                  <xsl:for-each-group select="$this-rng//rng:element" group-by="@name">
                     <xsl:sort select="lower-case(current-grouping-key())"/>
                     <xsl:call-template name="rng-node-to-docbook-section">
                        <xsl:with-param name="rng-element-or-attribute-group"
                           select="current-group()"/>
                     </xsl:call-template>
                  </xsl:for-each-group>
                  <xsl:for-each-group select="$this-rng//rng:attribute" group-by="@name">
                     <xsl:sort select="lower-case(current-grouping-key())"/>
                     <xsl:call-template name="rng-node-to-docbook-section">
                        <xsl:with-param name="rng-element-or-attribute-group"
                           select="current-group()"/>
                     </xsl:call-template>
                  </xsl:for-each-group>
                  <xsl:if test="not(exists($this-rng//(rng:element, rng:attribute)))">
                     <para>
                        <xsl:value-of
                           select="'No attributes or elements are defined for ' || $this-name || '.'"
                        />
                     </para>
                  </xsl:if>
               </section>
            </xsl:for-each>
            <section>
               <title>TAN patterns</title>
               <xsl:for-each-group select="$rng-collection-without-TEI//rng:define" group-by="@name">
                  <xsl:sort select="lower-case(@name)"/>
                  <xsl:call-template name="rng-node-to-docbook-section">
                     <xsl:with-param name="rng-element-or-attribute-group" select="current-group()"
                     />
                  </xsl:call-template>
               </xsl:for-each-group>
            </section>
         </chapter>
      </xsl:result-document>
      <xsl:result-document href="../../guidelines/inclusions/keywords.xml">
         <chapter version="5.0" xml:id="keywords-master-list">
            <xsl:variable name="intro-text" as="xs:string">In this section are collected all
               official TAN keywords, i.e., values of @which predefined by TAN for certain elements.
               Remember, these keywords are not @xml:id values. They may contain punctuation,
               spaces, and so forth. For more on the use of these keywords, see @which, specific
               elements, or various examples. </xsl:variable>
            <title>Official TAN keywords</title>
            <para>
               <xsl:copy-of select="tan:prep-string-for-docbook(normalize-space($intro-text))"/>
            </para>
            <xsl:apply-templates select="$keyword-collection" mode="keyword-to-docbook"/>
         </chapter>
      </xsl:result-document>
      <xsl:result-document href="../../guidelines/inclusions/variables-keys-functions-and-templates.xml">
         <chapter version="5.0" xml:id="variables-keys-functions-and-templates">
            <title>TAN variables, keys, functions, and templates</title>
            <para>
               <xsl:value-of
                  select="
                     'The ' || count(distinct-values($function-library-variables/@name)) || ' global variables, ' ||
                     count(distinct-values($function-library-keys/@name)) || ' keys, ' ||
                     count(distinct-values($function-library-functions/@name)) || ' functions, and ' ||
                     count(distinct-values(for $i in $function-library-templates/(@name, @mode)
                     return
                        tokenize($i, '\s+'))) || ' templates (Ŧ = named template; ŧ = template mode) defined in the TAN function library, are the following:'"
               />
            </para>
            <xsl:for-each-group
               select="($function-library-keys, $function-library-functions, $function-library-variables, $function-library-templates)"
               group-by="
                  if (exists(@name)) then
                     substring(replace(@name, '^\w+:', ''), 1, 1)
                  else
                     for $i in tokenize(@mode, '\s+')
                     return
                        substring(replace($i, '^\w+:', ''), 1, 1)">
               <xsl:sort select="lower-case(current-grouping-key())"/>
               <xsl:variable name="this-letter" select="lower-case(current-grouping-key())"/>
               <para>
                  <xsl:for-each-group select="current-group()"
                     group-by="
                        if (exists(@name)) then
                           (name() || ' ' || @name)
                        else
                           for $i in tokenize(@mode, '\s+')[matches(lower-case(.), ('^' || $this-letter))]
                           return
                              (name() || ' ' || $i)">
                     <xsl:sort
                        select="lower-case(replace(tokenize(current-grouping-key(), '\s+')[2], '^\w+:', ''))"/>
                     <xsl:variable name="node-type-and-name"
                        select="tokenize(current-grouping-key(), '\s+')"/>
                     <xsl:copy-of
                        select="tan:prep-string-for-docbook(tan:string-representation-of-component($node-type-and-name[2], $node-type-and-name[1], exists(current-group()/@mode)))"/>
                     <xsl:text> </xsl:text>
                  </xsl:for-each-group>
               </para>
               <xsl:text>&#xA;</xsl:text>
            </xsl:for-each-group>
            <!-- First, collate by TAN hierarchy the variables, keys, functions, and named templates, which are all unique and so can take an id; because template modes spread out across components, they need to be handled outside the TAN hierarchical structure -->
            <xsl:for-each
               select="$all-functions[replace(tan:cfn(.), '-functions', '') = $sequence-of-sections/descendant-or-self::*/@n]">
               <xsl:sort>
                  <!-- sort according to the sequence defined in $sequence-of-sections -->
                  <xsl:variable name="this-cfn" select="replace(tan:cfn(.), '-functions', '')"/>
                  <xsl:copy-of
                     select="count($sequence-of-sections//*[@n = $this-cfn]/(preceding::*, ancestor-or-self::*))"
                  />
               </xsl:sort>
               <xsl:variable name="this-function-file" select="."/>
               <xsl:variable name="this-name" select="replace(tan:cfn(.), '-functions', '')"/>
               <xsl:variable name="these-components-to-traverse"
                  select="$this-function-file/*/*[self::xsl:variable or self::xsl:key or self::xsl:function or self::xsl:template[@name]]"/>
               <section>
                  <title>
                     <xsl:value-of
                        select="$this-name || ' global variables, keys, and functions summarized'"/>
                  </title>
                  <xsl:for-each-group select="$these-components-to-traverse" group-by="name()">
                     <!-- This is a group of variables, keys, functions, and named templates, but not template modes, which are handled later -->
                     <xsl:sort
                        select="index-of(('xsl:variable', 'xsl:key', 'xsl:function', 'xsl:template'), current-grouping-key())"/>
                     <xsl:variable name="this-type-of-component"
                        select="replace(current-grouping-key(), 'xsl:(.+)', '$1')"/>
                     <section>
                        <title>
                           <xsl:value-of select="$this-type-of-component || 's'"/>
                        </title>
                        <xsl:for-each select="current-group()">
                           <!-- This is an individual variable, key, function, or named template -->
                           <xsl:sort select="lower-case(@name)"/>
                           <xsl:variable name="what-depends-on-this"
                              select="tan:xslt-dependencies(@name, $this-type-of-component, false(), $all-functions)[name() = ('xsl:function', 'xsl:variable', 'xsl:template', 'xsl:key')]"/>


                           <section
                              xml:id="{$this-type-of-component || '-' || replace(@name,'^\w+:','')}">
                              <title>
                                 <code>
                                    <xsl:value-of
                                       select="tan:string-representation-of-component(@name, current-grouping-key())"
                                    />
                                 </code>
                              </title>
                              <!-- Insert remarks specific to the type of component, e.g., the input and output expectations of a function -->
                              <xsl:choose>
                                 <xsl:when test="$this-type-of-component = 'key'">
                                    <para>Looks for elements matching <code><xsl:value-of
                                             select="@match"/></code></para>
                                 </xsl:when>
                                 <xsl:when test="$this-type-of-component = 'function'">
                                    <xsl:variable name="these-params" select="xsl:param"/>
                                    <xsl:variable name="param-text" as="xs:string*"
                                       select="
                                          for $i in $these-params
                                          return
                                             '$' || $i/@name || (if (exists($i/@as)) then
                                                (' as ' || $i/@as)
                                             else
                                                ())"/>
                                    <para>
                                       <code><xsl:value-of select="@name"/>(<xsl:value-of
                                             select="string-join($param-text, ', ')"/>) <xsl:if
                                             test="exists(@as)">as <xsl:value-of select="@as"
                                             /></xsl:if></code>
                                    </para>
                                 </xsl:when>
                                 <xsl:when test="$this-type-of-component = 'variable'">
                                    <xsl:choose>
                                       <xsl:when test="exists(@select)">
                                          <para>Definition: <code><xsl:copy-of
                                                  select="tan:copy-of-except(tan:prep-string-for-docbook(@select), (), (), (), (), 'code')"
                                                /></code></para>
                                       </xsl:when>
                                       <xsl:otherwise>
                                          <para>This variable has a complex definition. See
                                             stylesheet for definiton.</para>
                                       </xsl:otherwise>
                                    </xsl:choose>
                                 </xsl:when>
                              </xsl:choose>
                              <!-- Insert prefatory comments placed inside the component -->
                              <xsl:copy-of select="tan:component-comments-to-docbook(.)"/>
                              <!-- State what depends on this -->
                              <xsl:copy-of select="tan:component-dependees-to-docbook(.)"/>
                              <!-- State what it depends upon -->
                              <xsl:copy-of select="tan:component-dependencies-to-docbook(.)"/>
                           </section>
                           <xsl:text>&#xA;</xsl:text>
                        </xsl:for-each>
                     </section>
                     <xsl:text>&#xA;</xsl:text>
                  </xsl:for-each-group>
                  <xsl:if test="not(exists($these-components-to-traverse))">
                     <para>
                        <xsl:value-of
                           select="'No variables, keys, or functions are defined for ' || $this-name || '.'"
                        />
                     </para>
                  </xsl:if>
               </section>
               <xsl:text>&#xA;</xsl:text>
            </xsl:for-each>
            <section>
               <title>Mode templates</title>
               <xsl:for-each-group select="$function-library-templates[@mode]"
                  group-by="tokenize(@mode, '\s+')">
                  <xsl:sort select="lower-case(current-grouping-key())"/>
                  <xsl:variable name="this-template-id" select="lower-case(current-grouping-key())"/>
                  <section xml:id="{'template-' || replace($this-template-id,'#','')}">
                     <title>
                        <code>ŧ <xsl:value-of select="current-grouping-key()"/></code>
                     </title>
                     <para><xsl:value-of select="count(current-group())"/> component<xsl:if
                           test="count(current-group()) gt 1">s</xsl:if>: <xsl:for-each-group
                           select="current-group()" group-by="tan:cfn(.)">
                           <code><xsl:value-of select="current-grouping-key() || '.xsl '"/></code>
                        </xsl:for-each-group></para>
                     <xsl:copy-of select="tan:component-comments-to-docbook(current-group())"/>
                     <xsl:copy-of select="tan:component-dependees-to-docbook(current-group()[1])"/>
                     <xsl:copy-of select="tan:component-dependencies-to-docbook(current-group())"/>
                  </section>
               </xsl:for-each-group>
            </section>
         </chapter>
      </xsl:result-document>
      <xsl:result-document href="../../guidelines/inclusions/errors.xml">
         <chapter version="5.0" xml:id="errors">
            <title>Errors</title>
            <para>Below is a list of specific TAN errors</para>
            <xsl:apply-templates select="$errors//*[@xml:id]" mode="errors-to-docbook"/>
         </chapter>
      </xsl:result-document>
   </xsl:template>
   <xsl:template name="rng-node-to-docbook-section">
      <!-- This is the main mechanism for populating sections that document an element or attribute -->
      <xsl:param name="rng-element-or-attribute-group" as="element()*"/>
      <xsl:variable name="this-group" select="$rng-element-or-attribute-group"/>
      <xsl:variable name="this-node-type" select="name($this-group[1])"/>
      <xsl:variable name="this-node-name" select="$this-group[1]/@name"/>
      <xsl:variable name="containing-definitions" select="$this-group/parent::rng:define"/>
      <xsl:variable name="possible-parents-of-this-node"
         select="
            $this-group/(ancestor::rng:element, rng:define)[last()],
            $rng-collection-without-TEI//rng:ref[@name = ($this-node-name, $containing-definitions/@name)]/(ancestor::rng:element, ancestor::rng:define)[last()]"/>
      <xsl:variable name="possible-parents-norm">
         <xsl:for-each select="$possible-parents-of-this-node">
            <xsl:variable name="this-name" select="@name"/>
            <xsl:choose>
               <xsl:when test="count(rng:*) gt 1 or not(rng:element or rng:attribute)">
                  <xsl:sequence select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence
                     select="$rng-collection-without-TEI//rng:ref[@name = ($this-name)]/(ancestor::rng:element, ancestor::rng:define)[last()]"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <section xml:id="{$this-node-type || '-' || replace($this-node-name,':','')}">
         <title>
            <code>
               <xsl:copy-of select="tan:string-representation-of-component($this-node-name, $this-node-type)"/>
            </code>
         </title>
         <!-- part 1, documentation -->
         <xsl:apply-templates select="$this-group/a:documentation" mode="rng-to-docbook"/>
         <!-- part 2, formal definiton -->
         <synopsis>
            <emphasis>Formal Definition&#xa;</emphasis>
            <xsl:apply-templates select="$this-group/rng:*" mode="formaldef">
               <xsl:with-param name="current-indent" select="$indent" tunnel="yes"/>
            </xsl:apply-templates>
         </synopsis>
         <!-- part 3, parents -->
         <xsl:if test="exists($possible-parents-of-this-node)">
            <para>
               <xsl:text>Used by: </xsl:text>
               <xsl:for-each-group select="$possible-parents-of-this-node"
                  group-by="name() || '_' || @name">
                  <xsl:variable name="this-key" select="tokenize(current-grouping-key(), '_')"/>
                  <xsl:if test="position() gt 1">
                     <xsl:text>, </xsl:text>
                  </xsl:if>
                  <xsl:copy-of
                     select="tan:prep-string-for-docbook(tan:string-representation-of-component($this-key[2], $this-key[1]))"
                  />
               </xsl:for-each-group>
            </para>
         </xsl:if>
         <!-- part 4 and 5, errors and warnings and examples -->
         <xsl:choose>
            <xsl:when test="$this-node-type = 'element'">
               <xsl:apply-templates mode="context-errors-to-docbook"
                  select="$errors//tan:group[tokenize(@affects-element, '\s+') = $this-node-name]/tan:*"/>
               <xsl:copy-of select="tan:examples($this-node-name, false())"/>
            </xsl:when>
            <xsl:when test="$this-node-type = 'attribute'">
               <xsl:apply-templates mode="context-errors-to-docbook"
                  select="$errors//tan:group[tokenize(@affects-attribute, '\s+') = $this-node-name]/tan:*"/>
               <xsl:copy-of select="tan:examples($this-node-name, true())"/>
            </xsl:when>
         </xsl:choose>
      </section>
   </xsl:template>

   <xsl:mode name="rng-to-docbook" on-no-match="shallow-copy"/>
   <xsl:template match="a:documentation[parent::rng:element or parent::rng:attribute]"
      mode="rng-to-docbook">
      <xsl:variable name="parent-type" select="lower-case(name(..))"/>
      <para>
         <xsl:if test="not(preceding-sibling::a:documentation)">
            <xsl:value-of select="'The ' || $parent-type || ' '"/>
            <code>
               <xsl:value-of select="../@name"/>
            </code>
            <xsl:text> </xsl:text>
         </xsl:if>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>
   <xsl:template match="a:documentation[parent::rng:define]" mode="rng-to-docbook">
      <xsl:variable name="this-name" select="replace(base-uri(.), '.+/(.+)\.rng$', '$1')"/>
      <para>
         <xsl:value-of select="$this-name || ': '"/>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>

   <!-- part 4, errors -->
   <xsl:mode name="context-errors-to-docbook" on-no-match="shallow-skip"/>
   <xsl:template match="tan:error | tan:fatal" mode="context-errors-to-docbook">
      <caution>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
         </para>
      </caution>
   </xsl:template>
   <xsl:template match="tan:warning" mode="context-errors-to-docbook">
      <important>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
            <xsl:if test="exists(tan:message)">
               <xsl:text> </xsl:text>
               <quote>
                  <xsl:copy-of select="tan:prep-string-for-docbook(tan:message)"/>
               </quote>
            </xsl:if>
         </para>
      </important>
   </xsl:template>
   <xsl:template match="tan:info" mode="context-errors-to-docbook">
      <info>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
         </para>
      </info>
   </xsl:template>

   <xsl:function name="tan:cfn" as="xs:string*">
      <!-- Input: any items -->
      <!-- Output: the Current File Name, without extension, of the host document node of each item -->
      <xsl:param name="item" as="item()*"/>
      <xsl:for-each select="$item">
         <xsl:value-of select="replace(base-uri(.), '.+/(.+)\.\w+$', '$1')"/>
      </xsl:for-each>
   </xsl:function>

</xsl:stylesheet>
