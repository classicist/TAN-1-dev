<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   exclude-result-prefixes="xs math xd tan fn tei functx sch" version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>Aug 16, 2016</xd:p>
         <xd:p>Variables, functions, and templates for all TAN files. Written primarily for
            Schematron validation, but suitable for general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="../regex/regex-ext-tan-functions.xsl"/>
   <xsl:include href="../errors/TAN-core-errors.xsl"/>
   <xsl:include href="diff-for-xslt2.xsl"/>

   <xsl:character-map name="tan">
      <!-- This map included, so that users of TAN files can see where ZWJs and soft hyphens are in use. -->
      <xsl:output-character character="&#x200d;" string="&amp;#x200d;"/>
      <xsl:output-character character="&#xad;" string="&amp;#xad;"/>
   </xsl:character-map>

   <!-- CORE GLOBAL VARIABLES -->

   <!-- general -->
   <xsl:variable name="regex-escaping-characters" as="xs:string"
      select="'[\.\[\]\\\|\-\^\$\?\*\+\{\}\(\)]'"/>
   <xsl:variable name="regex-characters-not-permitted" select="'[&#xA0;&#x2000;-&#x200a;]'"/>
   <xsl:variable name="quot" select="'&quot;'"/>
   <xsl:variable name="apos" select='"&apos;"'/>
   <xsl:variable name="empty-doc" as="document-node()">
      <xsl:document/>
   </xsl:variable>
   <xsl:variable name="erroneously-looped-doc" as="document-node()">
      <xsl:document>
         <xsl:copy-of select="tan:error('inc03')"/>
      </xsl:document>
   </xsl:variable>
   <xsl:variable name="now" select="tan:dateTime-to-decimal(current-dateTime())"/>

   <!--<xsl:variable name="class-1-root-names" select="('TAN-T', 'TEI')"/>
   <xsl:variable name="class-2-root-names" select="('TAN-A-div', 'TAN-A-tok', 'TAN-LM')"/>
   <xsl:variable name="class-3-root-names" select="('TAN-mor', 'TAN-key', 'TAN-rdf')"/>
   <xsl:variable name="all-root-names"
      select="$class-1-root-names, $class-2-root-names, $class-3-root-names"/>-->
   <xsl:function name="tan:class-number" as="xs:integer*">
      <!-- Input: any nodes of a TAN document
      Output: one digit per node, specifying which TAN class the file fits, based on the name of the root element.
      If no match is found in the root element, 0 is returned -->
      <xsl:param name="nodes" as="node()*"/>
      <xsl:for-each select="$nodes">
         <xsl:choose>
            <xsl:when test="exists(root()/(tan:TAN-T, tei:TEI/tan:head))">
               <xsl:copy-of select="1"/>
            </xsl:when>
            <xsl:when test="exists(root()/(tan:TAN-A-div, tan:TAN-A-tok, tan:TAN-LM))">
               <xsl:copy-of select="2"/>
            </xsl:when>
            <xsl:when test="exists(root()/(tan:TAN-mor, tan:TAN-key, tan:TAN-rdf))">
               <xsl:copy-of select="3"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="0"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:variable name="elements-that-must-always-refer-to-tan-files"
      select="
         ('morphology',
         'inclusion',
         'key')"/>
   <xsl:variable name="tag-urn-regex-pattern"
      select="'tag:([\-a-zA-Z0-9._%+]+@)?[\-a-zA-Z0-9.]+\.[A-Za-z]{2,4},\d{4}(-(0\d|1[0-2]))?(-([0-2]\d|3[01]))?:\S+'"/>

   <xsl:variable name="all-functions" select="collection('../collection.xml')"/>
   <xsl:variable name="all-schemas" select="collection('../../schemas/collection.xml')"/>

   <xsl:variable name="TAN-namespace" select="'tag:textalign.net,2015'"/>
   <xsl:variable name="id-idrefs" select="doc('TAN-idrefs.xml')"/>

   <xsl:param name="separator-hierarchy" select="' '" as="xs:string"/>
   <xsl:variable name="separator-hierarchy-regex" select="tan:escape($separator-hierarchy)"
      as="xs:string"/>

   <!-- If one wishes to see if an entire string matches the following patterns defined by these 
        variables, they must appear between the regular expression anchors ^ and $. -->
   <xsl:variable name="roman-numeral-pattern"
      select="'m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})'"/>
   <xsl:variable name="letter-numeral-pattern"
      select="'a+|b+|c+|d+|e+|f+|g+|h+|i+|j+|k+|l+|m+|n+|o+|p+|q+|r+|s+|t+|u+|v+|w+|x+|y+|z+'"/>
   <xsl:variable name="n-type-pattern" xml:id="v-n-type-pattern"
      select="
         (concat('^(', $roman-numeral-pattern, ')$'),
         '^(\d+)$',
         concat('^(\d+)(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')(\d+)$'),
         '(.)')"/>
   <xsl:variable name="n-type" xml:id="v-n-type"
      select="
         ('i',
         '1',
         '1a',
         'a',
         'a1',
         '$')"/>
   <xsl:variable name="n-type-label" xml:id="v-n-type-label"
      select="
         ('Roman numerals',
         'Arabic numerals',
         'Arabic numerals + alphabet numeral',
         'alphabet numeral',
         'alphabet numeral + Arabic numeral',
         'string')"/>

   <!-- self -->
   <xsl:variable name="root" select="/"/>
   <xsl:variable name="self-resolved" select="tan:resolve-doc(/)" as="document-node()"/>
   <xsl:variable name="self-core-errors-marked" as="document-node()">
      <xsl:variable name="pass-1">
         <xsl:apply-templates select="$self-resolved" mode="core-attribute-errors"/>
      </xsl:variable>
      <xsl:document>
         <xsl:apply-templates select="$pass-1" mode="core-errors"/>
      </xsl:document>
   </xsl:variable>

   <xsl:variable name="head" select="$self-resolved/*/tan:head"/>
   <xsl:variable name="body" select="$self-resolved/*/(tan:body, tei:text/tei:body)"/>
   <xsl:variable name="doc-id" select="/*/@id"/>
   <xsl:variable name="doc-uri" select="base-uri(/*)"/>
   <xsl:variable name="doc-parent-directory" select="replace($doc-uri, '[^/]+$', '')"/>
   <xsl:variable name="source-ids"
      select="
         if (exists($head/tan:source/@xml:id)) then
            $head/tan:source/@xml:id
         else
            for $i in (1 to count($head/tan:source))
            return
               string($i)"/>
   <xsl:variable name="all-ids"
      select="($head//@xml:id, /tei:TEI//descendant-or-self::tei:*/@xml:id)"/>
   <xsl:variable name="all-iris" select="$head//tan:IRI[not(ancestor::tan:error)]"/>
   <xsl:variable name="duplicate-ids" select="$all-ids[index-of($all-ids, .)[2]]"/>
   <xsl:variable name="duplicate-iris" select="$all-iris[index-of($all-iris, .)[2]]"/>
   <xsl:variable name="doc-namespace"
      select="substring-before(substring-after($doc-id, 'tag:'), ':')"/>
   <xsl:variable name="primary-agent" as="element()?"
      select="($head/tan:agent[tan:IRI[matches(., concat('^tag:', $doc-namespace))]])[1]"/>

   <!-- inclusions -->
   <xsl:variable name="inclusions-1st-da"
      select="tan:resolve-doc(tan:get-1st-doc(/*/tan:head/tan:inclusion), false(), 'incl', /*/tan:head/tan:inclusion/@xml:id, (), ())"
      as="document-node()*"/>
   <!-- keys -->
   <xsl:key name="item-via-node-name" match="tan:item"
      use="tokenize(string-join(((ancestor-or-self::*/@affects-element)[last()], (ancestor-or-self::*/@affects-attribute)[last()]), ' '), '\s+')"/>
   <xsl:key name="item-via-group-name" match="tan:item"
      use="tokenize(string-join((@group, ancestor::tan:group/@type), ' '), '\s+')"/>
   <xsl:variable name="TAN-keyword-files" as="document-node()*"
      select="collection('../../TAN-key/collection.xml')"/>
   <xsl:variable name="TAN-keywords" as="document-node()*">
      <xsl:for-each select="$TAN-keyword-files">
         <xsl:document>
            <xsl:apply-templates mode="resolve-href"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="relationship-keywords-for-tan-files"
      select="tan:get-attr-which-definition('relationship', (), 'TAN files')"/>
   <xsl:variable name="keys-1st-da" select="tan:resolve-doc(tan:get-1st-doc($head/tan:key))"/>
   <xsl:variable name="all-keywords" select="$keys-1st-da, $TAN-keywords" as="document-node()*"/>
   <!-- sources -->
   <xsl:variable name="sources-1st-da"
      select="tan:resolve-doc(tan:get-1st-doc($head/tan:source), false(), 'src', $source-ids, (), ())"/>
   <!-- see-also, context -->
   <xsl:variable name="see-also-1st-da"
      select="tan:resolve-doc(tan:get-1st-doc($head/tan:see-also))"/>
   <xsl:variable name="context-1st-da" select="$see-also-1st-da[*/self::tan:TAN-rdf]"/>
   <!-- token definitions -->
   <xsl:variable name="token-definitions-reserved" select="$TAN-keywords//tan:token-definition"/>

   <!-- CORE FUNCTIONS -->

   <xsl:function name="tan:base-uri" as="xs:anyURI?">
      <!-- input: any node
      output: the base uri of the node's document
      This differs from fn:base-uri in that it first looks for a @base-uri stamped at the document node. 
      This is important because many TAN documents will be transformed and bound to variables, and divorced from
      their original URI context. -->
      <xsl:param name="any-node" as="node()?"/>
      <xsl:copy-of select="(root($any-node)/*/@base-uri, base-uri($any-node))[1]"/>
   </xsl:function>
   <xsl:function name="tan:get-1st-doc" as="document-node()*">
      <!-- input: any TAN elements naming files (e.g., <source>, <see-also>, <inclusion>, <key>;
         an indication whether some basic errors should be checked if the retrieved file is a TAN document
         output: the first document available for each element, plus/or any relevant error messages.
      -->
      <xsl:param name="TAN-elements" as="element()*"/>
      <xsl:for-each select="$TAN-elements">
         <xsl:variable name="this-element" select="."/>
         <xsl:variable name="this-class" select="tan:class-number(.)"/>
         <xsl:variable name="first-la" select="tan:first-loc-available(.)"/>
         <xsl:choose>
            <xsl:when test="string-length($first-la) lt 1">
               <xsl:document>
                  <xsl:choose>
                     <xsl:when
                        test="not((self::tan:master-location, self::tan:location, tan:location))">
                        <xsl:copy-of select="$empty-doc"/>
                     </xsl:when>
                     <xsl:when test="self::tan:inclusion">
                        <xsl:copy-of select="tan:error('inc04')"/>
                     </xsl:when>
                     <xsl:when test="self::tan:key">
                        <xsl:copy-of select="tan:error('whi04')"/>
                     </xsl:when>
                     <xsl:when test="$this-class = 1">
                        <xsl:copy-of select="tan:error('wrn01')"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="tan:error('loc01')"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:document>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="doc($first-la)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:first-loc-available" as="xs:string*">
      <!-- Input: An element that contains one or more tan:location elements -->
      <!-- Output: the value of the first tan:location/@href to point to a document available, resolved If no location is available nothing is returned. -->
      <xsl:param name="elements-that-are-locations-or-parents-of-locations" as="element()*"/>
      <xsl:for-each select="$elements-that-are-locations-or-parents-of-locations">
         <xsl:variable name="base-uri" select="tan:base-uri(.)"/>
         <xsl:copy-of
            select="
               (for $i in (self::tan:master-location, self::tan:location, tan:location)/@href,
                  $j in resolve-uri($i, string($base-uri))
               return
                  if (doc-available($j)) then
                     $j
                  else
                     ())[1]"
         />
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:get-doc-hist" as="element()*">
      <!-- Input: any TAN document
         Output: a sequence of elements with @when, @ed-when, and @when-accessed, sorted from most recent to least;
         each element includes @when-sort, a decimal that represents the value of the most recent time-date stamp in that element
      -->
      <xsl:param name="TAN-doc" as="document-node()*"/>
      <xsl:for-each select="$TAN-doc">
         <xsl:variable name="doc-hist-raw" as="element()*">
            <xsl:for-each select=".//*[@when | @ed-when | @when-accessed]">
               <xsl:variable name="these-dates" as="xs:decimal*"
                  select="
                     for $i in (@when | @ed-when | @when-accessed)
                     return
                        tan:dateTime-to-decimal($i)"/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="when-sort" select="max($these-dates)"/>
                  <xsl:copy-of select="text()[matches(., '\S')]"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:variable>
         <history>
            <xsl:copy-of select="*/@*"/>
            <xsl:for-each select="$doc-hist-raw">
               <xsl:sort select="@when-sort" order="descending"/>
               <xsl:copy-of select="."/>
            </xsl:for-each>
         </history>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:resolve-doc" as="document-node()*">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="TAN-documents" as="document-node()*"/>
      <xsl:copy-of select="tan:resolve-doc($TAN-documents, true(), (), (), (), ())"/>
   </xsl:function>
   <xsl:function name="tan:resolve-doc" as="document-node()*">
      <!-- test to see if we can get around function loop error -->
      <xsl:param name="TAN-documents" as="document-node()*"/>
      <xsl:param name="leave-breadcrumbs" as="xs:boolean"/>
      <xsl:param name="add-attr-to-root-element-named-what" as="xs:string?"/>
      <xsl:param name="add-what-val-to-new-root-attribute" as="xs:string*"/>
      <xsl:param name="restrict-inclusion-to-what-element-names" as="xs:string*"/>
      <xsl:param name="doc-ids-already-checked" as="xs:string*"/>
      <xsl:for-each select="$TAN-documents">
         <xsl:variable name="this-doc" select="."/>
         <xsl:variable name="this-doc-no" select="position()"/>
         <xsl:variable name="this-doc-stamped-attr-val"
            select="$add-what-val-to-new-root-attribute[$this-doc-no]"/>
         <!--<xsl:variable name="this-base-uri" select="tan:base-uri($this-doc)"/>-->
         <xsl:variable name="this-doc-id" select="$this-doc/*/@id"/>
         <xsl:variable name="new-doc-ids-checked-so-far"
            select="($doc-ids-already-checked, $this-doc-id)"/>
         <xsl:variable name="elements-that-must-be-expanded"
            select="
               $this-doc//*[@include][if (exists($restrict-inclusion-to-what-element-names)) then
                  name() = $restrict-inclusion-to-what-element-names
               else
                  true()]"/>
         <xsl:variable name="included-docs-resolved" as="document-node()*">
            <xsl:for-each-group select="$elements-that-must-be-expanded"
               group-by="tokenize(tan:normalize-text(@include), ' ')">
               <xsl:variable name="this-inclusion-idref" select="current-grouping-key()"/>
               <xsl:variable name="this-inclusion-element"
                  select="$this-doc/*/tan:head/tan:inclusion[@xml:id = $this-inclusion-idref]"/>
               <xsl:variable name="this-inclusion-doc"
                  select="tan:get-1st-doc($this-inclusion-element)"/>
               <xsl:variable name="names-of-elements-to-fetch"
                  select="
                     for $i in current-group()
                     return
                        name($i)"
                  as="xs:string*"/>
               <xsl:choose>
                  <xsl:when test="not(exists($this-inclusion-element))">
                     <xsl:document>
                        <xsl:copy-of select="tan:error('tan05')"/>
                     </xsl:document>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of
                        select="tan:resolve-doc($this-inclusion-doc, false(), 'inclusion', $this-inclusion-idref, $names-of-elements-to-fetch, $new-doc-ids-checked-so-far)"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each-group>
         </xsl:variable>
         <xsl:variable name="doc-stamped" as="document-node()?">
            <xsl:document>
               <xsl:apply-templates mode="first-stamp">
                  <xsl:with-param name="leave-breadcrumbs" select="$leave-breadcrumbs"/>
                  <xsl:with-param name="stamp-root-element-with-attr-name"
                     select="$add-attr-to-root-element-named-what"/>
                  <xsl:with-param name="stamp-root-element-with-attr-val"
                     select="$this-doc-stamped-attr-val"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:variable>
         <xsl:variable name="doc-with-n-and-ref-converted" as="document-node()?">
            <xsl:variable name="elements-to-convert"
               select="$this-doc/(tan:*/tan:body, tei:TEI/tei:text/tei:body)/*"/>
            <xsl:variable name="ambiguous-numeral-types"
               select="
                  tan:analyze-elements-with-numeral-attributes($elements-to-convert, if (name($this-doc/*) = ('TAN-T', 'TEI')) then
                     'type'
                  else
                     (), true(), false())"
               as="element()*"/>
            <xsl:document>
               <xsl:apply-templates select="$doc-stamped" mode="arabic-numerals">
                  <xsl:with-param name="ambiguous-numeral-types" select="$ambiguous-numeral-types"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:variable>
         <xsl:variable name="doc-attr-include-expanded" as="document-node()?">
            <xsl:choose>
               <xsl:when test="not(exists($elements-that-must-be-expanded))">
                  <xsl:sequence select="$doc-with-n-and-ref-converted"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:document>
                     <xsl:apply-templates select="$doc-with-n-and-ref-converted"
                        mode="resolve-attr-include">
                        <xsl:with-param name="tan-doc-ids-checked-so-far"
                           select="$new-doc-ids-checked-so-far" tunnel="yes"/>
                        <xsl:with-param name="docs-whence-inclusion-resolved"
                           select="$included-docs-resolved" tunnel="yes"/>
                     </xsl:apply-templates>
                  </xsl:document>
                  <!--<xsl:copy-of
                           select="tan:strip-duplicates($pass1, $names-of-elements-with-attr-include)"
                        />-->
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:variable name="extra-keys-1st-da" select="tan:get-1st-doc($doc-attr-include-expanded/*/tan:head/tan:key[not(@include)])"/>
         <xsl:variable name="extra-keys-resolved"
            select="tan:resolve-doc($extra-keys-1st-da, false(), (), (), ('group', 'item'), ())"
            as="document-node()*"/>
         <xsl:variable name="duplicate-keys-removed" as="document-node()*">
            <xsl:for-each select="$extra-keys-resolved">
               <xsl:variable name="pos" select="position()"/>
               <xsl:variable name="this-key" select="." as="document-node()"/>
               <xsl:if
                  test="
                  not(some $i in $extra-keys-resolved[position() lt $pos]
                  satisfies deep-equal($i/*, $this-key/*))">
                  <xsl:sequence select="."/>
               </xsl:if>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="doc-attr-which-expanded" as="document-node()?">
            <xsl:document>
               <xsl:apply-templates select="$doc-attr-include-expanded" mode="resolve-keyword">
                  <xsl:with-param name="extra-keys" select="$duplicate-keys-removed" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:variable>
         <xsl:choose>
            <xsl:when test="*/@id = $doc-ids-already-checked">
               <xsl:sequence select="."/>
            </xsl:when>
            <xsl:otherwise>
               <!--<xsl:copy-of select="$doc-stamped"/>-->
               <!--<xsl:copy-of select="$doc-attr-include-expanded"/>-->
               <!--<xsl:document><xsl:copy-of select="$doc-attr-include-expanded/*/tan:head/tan:key"/></xsl:document>-->
               <!--<xsl:copy-of select="$extra-keys-1st-da"/>-->
               <!--<xsl:copy-of select="$extra-keys-resolved"/>-->
               <!--<xsl:copy-of select="$duplicate-keys-removed"/>-->
               <xsl:copy-of select="$doc-attr-which-expanded"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:resolve-doc-old" as="document-node()*">
      <!-- Input: any number of TAN documents; boolean indicating whether documents should be breadcrumbed or not; optional name of an attribute and a sequence of strings to stamp in each document's root element as a way of providing another identifier for the document; a list of element names to which any inclusion should be restricted; a list of ids for documents that should not be used to generate inclusions.
      Output: those same documents, resolved, along the following steps:
           1. Stamp each document with @base-uri and the optional root attribute; resolve @href, putting the original (if different) in @orig-href
           2. Normalize @ref and @n, converting them whenever possible to Arabic numerals, and keeping the old versions as @orig-ref and @orig-n
           3. Resolve every element that has @include.
           4. Resolve every element that has @which.
           5. If anything happened at #3, remove any duplicate elements. -->
      <!-- This function and the functions connected with it are among the most important in the TAN library, since they provide critical stamping (for validation and diagnosing problems) and expand abbreviated parts (to explicitly state what is implied by @include and @which) of a TAN file. Perhaps more importantly, it is a recursive function that is used to resolve not only the beginning of the inclusion process but its middle and endpoints as well. -->
      <xsl:param name="TAN-documents" as="document-node()*"/>
      <xsl:param name="leave-breadcrumbs" as="xs:boolean"/>
      <xsl:param name="add-attr-to-root-element-named-what" as="xs:string?"/>
      <xsl:param name="add-what-val-to-new-root-attribute" as="xs:string*"/>
      <xsl:param name="restrict-inclusion-to-what-element-names" as="xs:string*"/>
      <xsl:param name="error-if-inclusion-has-what-ids" as="xs:string*"/>
      <xsl:variable name="docs-stamped" as="document-node()*">
         <xsl:for-each select="$TAN-documents">
            <xsl:variable name="pos" select="position()"/>
            <xsl:document>
               <xsl:apply-templates mode="first-stamp">
                  <xsl:with-param name="leave-breadcrumbs" select="$leave-breadcrumbs"/>
                  <xsl:with-param name="stamp-root-element-with-attr-name"
                     select="$add-attr-to-root-element-named-what"/>
                  <xsl:with-param name="stamp-root-element-with-attr-val"
                     select="$add-what-val-to-new-root-attribute[$pos]"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="docs-with-n-and-ref-converted" as="document-node()*">
         <xsl:for-each select="$docs-stamped">
            <xsl:variable name="this-doc" select="."/>
            <xsl:variable name="elements-to-convert"
               select="$this-doc/(tan:*/tan:body, tei:TEI/tei:text/tei:body, tan:*/tan:head/tan:declarations/tan:rename-div-ns)/*"/>
            <xsl:variable name="ambiguous-numeral-types"
               select="
                  tan:analyze-elements-with-numeral-attributes($elements-to-convert, if (name($this-doc/*) = ('TAN-T', 'TEI')) then
                     'type'
                  else
                     (), true(), false())"
               as="element()*"/>
            <xsl:document>
               <xsl:apply-templates mode="arabic-numerals">
                  <xsl:with-param name="ambiguous-numeral-types" select="$ambiguous-numeral-types"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="docs-attr-include-expanded" as="document-node()*">
         <xsl:for-each select="$docs-with-n-and-ref-converted">
            <xsl:variable name="this-doc" select="."/>
            <!--<xsl:variable name="this-base-uri" select="tan:base-uri($this-doc)"/>-->
            <xsl:variable name="this-doc-id" select="$this-doc/*/@id"/>
            <xsl:variable name="tan-doc-ids-checked-so-far"
               select="($error-if-inclusion-has-what-ids, $this-doc-id)"/>
            <xsl:variable name="these-elements-with-attr-include"
               select="
                  //*[@include][if (exists($restrict-inclusion-to-what-element-names)) then
                     name() = $restrict-inclusion-to-what-element-names
                  else
                     true()]"/>
            <xsl:variable name="names-of-elements-with-attr-include" as="xs:string*"
               select="
                  distinct-values(for $i in $these-elements-with-attr-include
                  return
                     name($i))"/>
            <xsl:variable name="inclusion-idrefs"
               select="
                  distinct-values(for $i in tan:normalize-text($these-elements-with-attr-include/@include)
                  return
                     tokenize($i, ' '))"/>
            <xsl:variable name="target-inclusion"
               select="
                  (: we use the for-return technique since we want strict one-to-one correlation between the list of idrefs and the resolved documents :)
                  for $i in $inclusion-idrefs
                  return
                     $this-doc/*/tan:head/tan:inclusion[@xml:id = $i]"/>
            <xsl:variable name="docs-whence-inclusion" select="tan:get-1st-doc($target-inclusion)"/>
            <xsl:variable name="docs-whence-inclusion-resolved" as="document-node()*"
               select="
                  for $i in $docs-whence-inclusion
                  return
                     if ($i/*/@id = $tan-doc-ids-checked-so-far) then
                        $erroneously-looped-doc
                     else
                        tan:resolve-doc($docs-whence-inclusion, false(), 'include', $inclusion-idrefs, $names-of-elements-with-attr-include, $tan-doc-ids-checked-so-far)"/>
            <xsl:choose>
               <xsl:when test="not(exists($these-elements-with-attr-include))">
                  <xsl:sequence select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="pass1" as="document-node()">
                     <xsl:document>
                        <xsl:apply-templates mode="resolve-attr-include">
                           <xsl:with-param name="tan-doc-ids-checked-so-far"
                              select="$tan-doc-ids-checked-so-far" tunnel="yes"/>
                           <xsl:with-param name="docs-whence-inclusion-resolved"
                              select="$docs-whence-inclusion-resolved" tunnel="yes"/>
                        </xsl:apply-templates>
                     </xsl:document>
                  </xsl:variable>
                  <!--<xsl:document><xsl:copy-of select="$target-inclusion"/></xsl:document>-->
                  <!--<xsl:copy-of select="$docs-whence-inclusion"/>-->
                  <!--<xsl:document><xsl:copy-of select="$names-of-elements-with-attr-include"/></xsl:document>-->
                  <!--<xsl:copy-of select="tan:resolve-doc($docs-whence-inclusion, false(), 'include', $inclusion-idrefs, $names-of-elements-with-attr-include, $tan-doc-ids-checked-so-far)"/>-->
                  <!--<xsl:copy-of select="$docs-whence-inclusion-resolved"/>-->
                  <!--<xsl:copy-of select="$pass1"/>-->
                  <xsl:copy-of
                     select="tan:strip-duplicates($pass1, $names-of-elements-with-attr-include)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="docs-attr-which-expanded" as="document-node()*">
         <xsl:for-each select="$docs-attr-include-expanded">
            <xsl:variable name="extra-keys-resolved"
               select="tan:resolve-doc(tan:get-1st-doc(*/tan:head/tan:key))" as="document-node()*"/>
            <xsl:variable name="duplicate-keys-removed" as="document-node()*">
               <xsl:for-each select="$extra-keys-resolved">
                  <xsl:variable name="pos" select="position()"/>
                  <xsl:variable name="this-key" select="." as="document-node()"/>
                  <xsl:if
                     test="
                        not(some $i in $extra-keys-resolved[position() lt $pos]
                           satisfies deep-equal($i/*, $this-key/*))">
                     <xsl:sequence select="."/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:variable>
            <xsl:document>
               <xsl:apply-templates mode="resolve-keyword">
                  <xsl:with-param name="extra-keys" select="$duplicate-keys-removed" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <!--<xsl:copy-of select="$docs-with-n-and-ref-converted"/>-->
      <!--<xsl:copy-of select="$docs-attr-include-expanded"/>-->
      <!--<xsl:copy-of select="$docs-attr-which-expanded"/>-->
      <xsl:choose>
         <xsl:when test="$TAN-documents/*/@id = $error-if-inclusion-has-what-ids">
            <xsl:copy-of select="$erroneously-looped-doc"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$docs-attr-which-expanded"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <!--<xsl:function name="tan:get-elements-new" as="element()*">
      <!-\- Input: any elements from a single TAN document; a sequence of strings of document uris already checked; a sequence of strings identifying document ids that have already been checked -\->
      <!-\- Output:  the same elements, resolving those that have @include and @which to their full version.-\->
      <xsl:param name="elements-to-get" as="element()*"/>
      <xsl:param name="uris-checked-so-far" as="xs:string*"/>
      <xsl:param name="tan-doc-ids-checked-so-far" as="xs:string*"/>
      <xsl:variable name="this-doc-root" select="root($elements-to-get[1])"/>
      <xsl:variable name="this-base-uri" select="tan:base-uri($this-doc-root)"/>
      <xsl:variable name="this-doc-id" select="root($elements-to-get[1])/*/@id"/>
      <xsl:variable name="supplemental-keys-to-get" as="element()*">
         <!-\- If an element to get has @which, and <key> isn't being fetched, then make sure to include every <key> 
            that has @include, so that all definitions pertaining to this document can be checked. -\->
         <xsl:if
            test="exists($elements-to-get[@which]) and not(exists($elements-to-get/self::tan:key))">
            <xsl:copy-of select="$this-doc-root/*/tan:head/tan:key[@include]"/>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="these-elem-inclusion" select="$this-doc-root/*/tan:head/tan:inclusion"/>
      <xsl:variable name="inclusion-idrefs" select="distinct-values(tokenize(tan:normalize-text($elements-to-get/@include), ' '))"/>
      <xsl:variable name="target-inclusion"
         select="(: we use the for-return technique since we want strict one-to-one correlation between the list of idrefs and the resolved documents :)
            for $i in $inclusion-idrefs
            return
               $these-elem-inclusion[@xml:id = $i]"
      />
      <xsl:variable name="this-inclusion-1st-da" select="tan:get-1st-doc($target-inclusion)"/>
      <xsl:variable name="pass1" as="element()*">
         <xsl:apply-templates select="$elements-to-get" mode="resolve-href"/>
      </xsl:variable>
      <xsl:variable name="pass2" as="element()*">
         <xsl:apply-templates select="$pass1" mode="resolve-attr-include"/>
      </xsl:variable>
      <!-\- results -\->
      <xsl:choose>
         <xsl:when test="not(exists($target-inclusion))">
            <xsl:for-each select="$elements-to-get">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:error('tan05')"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:when>
         <xsl:when test="exists($this-inclusion-1st-da/(tan:error, tan:fatal))">
            <xsl:for-each select="$elements-to-get">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="$this-inclusion-1st-da/(tan:error, tan:fatal)"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:when>
         <xsl:when
            test="($this-base-uri = $uris-checked-so-far) or ($this-doc-id = $tan-doc-ids-checked-so-far)">
            <xsl:for-each select="$elements-to-get">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:error('inc03')"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$pass2"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>-->
   <!--<xsl:function name="tan:get-elements" as="element()*">
      <!-\- Input: any elements from a TAN document; a sequence of strings of document uris already checked;
         a sequence of strings identifying document ids that have already been checked
         Output: the same elements, resolving those that have @include and @which
         to their full version.
         Warning: This function assumes that all input elements come from the same document, and that elements
         of the same name have all been chosen (has ramifications only for <key>: if <key> is an element to get, then
         it is assumed that the caller of the function is asking for all the instances of <key>)..
      -\->
      <xsl:param name="elements-to-get" as="element()*"/>
      <xsl:param name="uris-checked-so-far" as="xs:string*"/>
      <xsl:param name="tan-doc-ids-checked-so-far" as="xs:string*"/>
      <xsl:variable name="this-doc-root" select="root($elements-to-get[1])"/>
      <xsl:variable name="this-base-uri" select="tan:base-uri($this-doc-root)"/>
      <xsl:variable name="this-doc-id" select="root($elements-to-get[1])/*/@id"/>
      <xsl:variable name="supplemental-keys-to-get" as="element()*">
         <!-\- If an element to get has @which, and <key> isn't being fetched, then make sure to include every <key> 
            that has @include, so that all definitions pertaining to this document can be checked. -\->
         <xsl:if
            test="exists($elements-to-get[@which]) and not(exists($elements-to-get/self::tan:key))">
            <xsl:copy-of select="$this-doc-root/*/tan:head/tan:key[@include]"/>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="all-elements-to-fetch"
         select="$elements-to-get, $supplemental-keys-to-get" as="element()*"/>
      <xsl:variable name="these-elem-inclusion" select="$this-doc-root/*/tan:head/tan:inclusion"/>
      <!-\- first, return any element that doesn't have @which or @include -\->
      <xsl:apply-templates select="$all-elements-to-fetch[not((@include, @which))]"
         mode="resolve-href"/>
      <!-\- second, deal with @include. We bind it to a variable, so that resolution of @which doesn't need to repeat prior efforts -\->
      <xsl:variable name="fetched-inclusion-elements" as="element()*">
         <xsl:for-each-group select="$all-elements-to-fetch[@include]"
            group-by="tokenize(tan:normalize-text(@include), '\s')">
            <xsl:variable name="target-inclusion"
               select="$these-elem-inclusion[@xml:id = current-grouping-key()]"/>
            <xsl:variable name="this-inclusion-1st-da" select="tan:get-1st-doc($target-inclusion)"/>
            <xsl:variable name="element-names-to-get"
               select="
                  for $i in current-group()
                  return
                     name($i)"/>
            <xsl:choose>
               <xsl:when test="not(exists($target-inclusion))">
                  <xsl:for-each select="current-group()">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="tan:error('tan05')"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:when>
               <xsl:when test="exists($this-inclusion-1st-da/(tan:error, tan:fatal))">
                  <xsl:for-each select="current-group()">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="$this-inclusion-1st-da/tan:error"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:when>
               <xsl:when
                  test="($this-base-uri = $uris-checked-so-far) or ($this-doc-id = $tan-doc-ids-checked-so-far)">
                  <xsl:for-each select="current-group()">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="tan:error('inc03')"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of
                     select="tan:get-elements($this-inclusion-1st-da//*[name(.) = $element-names-to-get][not(name(parent::*) = $element-names-to-get)], ($uris-checked-so-far, $this-base-uri), ($tan-doc-ids-checked-so-far, $this-doc-id))"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:copy-of
         select="
            if (exists($supplemental-keys-to-get)) then
               $fetched-inclusion-elements[not(self::tan:key)]
            else
               $fetched-inclusion-elements"/>
      <xsl:if test="$elements-to-get[@which]">
         <!-\- third, if there are @which -ed elements then go get all the keys for the document, and resolve. -\->
         <xsl:variable name="these-keys"
            select="$this-doc-root/*/tan:head/tan:key[not(@include)], $fetched-inclusion-elements[self::tan:key]"/>
         <xsl:variable name="these-keys-1st-da" select="tan:get-1st-doc($these-keys)"/>
         <xsl:copy-of select="$these-keys-1st-da/(tan:error, tan:fatal)"/>
         <xsl:if test="not(exists($these-keys-1st-da/(tan:error, tan:fatal)))">
            <xsl:apply-templates select="$elements-to-get[@which]" mode="resolve-keyword">
               <xsl:with-param name="extra-keys" select="$these-keys-1st-da" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:if>
      </xsl:if>
   </xsl:function>-->

   <xsl:key name="q-ref" match="*" use="tan:q-ref(.)"/>
   <xsl:function name="tan:get-via-q-ref" as="node()*">
      <xsl:param name="q-ref" as="xs:string*"/>
      <xsl:param name="q-reffed-document" as="document-node()*"/>
      <xsl:for-each select="$q-reffed-document">
         <xsl:copy-of select="key('q-ref', $q-ref, .)"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:rom-to-int" as="xs:integer*">
      <!-- Change any roman numeral less than 5000 into an integer
         E.g., 'xliv' - > 44
      -->
      <xsl:param name="arg" as="xs:string*"/>
      <xsl:variable name="rom-cp"
         select="
            (109,
            100,
            99,
            108,
            120,
            118,
            105)"
         as="xs:integer+"/>
      <xsl:variable name="rom-cp-vals"
         select="
            (1000,
            500,
            100,
            50,
            10,
            5,
            1)"
         as="xs:integer+"/>
      <xsl:for-each select="$arg">
         <xsl:variable name="arg-lower" select="lower-case(.)"/>
         <xsl:choose>
            <xsl:when test="matches($arg-lower, concat('^', $roman-numeral-pattern, '$'))">
               <xsl:variable name="arg-seq" select="string-to-codepoints($arg-lower)"/>
               <xsl:variable name="arg-val-seq"
                  select="
                     for $i in $arg-seq
                     return
                        $rom-cp-vals[index-of($rom-cp, $i)]"/>
               <xsl:variable name="arg-val-mod"
                  select="
                     (for $i in (1 to count($arg-val-seq) - 1)
                     return
                        if ($arg-val-seq[$i] lt $arg-val-seq[$i + 1]) then
                           -1
                        else
                           1),
                     1"/>
               <xsl:value-of
                  select="
                     sum(for $i in (1 to count($arg-val-seq))
                     return
                        $arg-val-seq[$i] * $arg-val-mod[$i])"
               />
            </xsl:when>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:aaa-to-int" as="xs:integer*">
      <!-- Input: any alphabet numerals -->
      <!-- Output:the integer equivalent -->
      <!-- Sequence goes a, b, c, ... z, aa, bb, ..., aaa, bbb, ....  E.g., 'ccc' - > 55 -->
      <xsl:param name="arg" as="xs:string*"/>
      <xsl:for-each select="$arg">
         <xsl:variable name="arg-lower" select="lower-case(.)"/>
         <xsl:if test="matches($arg-lower, concat('^(', $letter-numeral-pattern, ')$'))">
            <xsl:variable name="arg-length" select="string-length($arg-lower)"/>
            <xsl:variable name="arg-val" select="string-to-codepoints($arg-lower)[1] - 96"/>
            <xsl:value-of select="$arg-val + ($arg-length - 1) * 26"/>
         </xsl:if>

      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:tokenize-leaf-div" as="element()?">
      <!-- Input: single string and a <tan:token-definition>. 
         Output: <tan:result> containing a sequence of elements, <tan:tok> and <tan:non-tok>,
        corresponding to fn:match and fn:non-match for fn:analyze-string() -->
      <xsl:param name="text" as="xs:string?"/>
      <xsl:param name="token-definition" as="element()?"/>
      <xsl:param name="count-toks" as="xs:boolean"/>
      <xsl:variable name="regex"
         select="($token-definition/@regex, $token-definitions-reserved[1]/@regex)[1]"/>
      <xsl:variable name="flags" select="$token-definition/@flags"/>
      <xsl:variable name="results" as="element()">
         <results regex="{$regex}" flags="{$flags}">
            <xsl:analyze-string select="$text" regex="{$regex}">
               <xsl:matching-substring>
                  <tok>
                     <xsl:value-of select="."/>
                  </tok>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <non-tok>
                     <xsl:value-of select="."/>
                  </non-tok>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </results>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$count-toks = false()">
            <xsl:copy-of select="$results"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="$results" mode="count-tokens"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:template match="tan:results" mode="count-tokens">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="max-toks" select="count(tan:tok)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:non-tok" mode="count-tokens">
      <non-tok n="{count(preceding-sibling::tan:non-tok) + 1}">
         <xsl:value-of select="."/>
      </non-tok>
   </xsl:template>
   <xsl:template match="tan:tok" mode="count-tokens">
      <tok n="{count(preceding-sibling::tan:tok) + 1}">
         <xsl:value-of select="."/>
      </tok>
   </xsl:template>

   <xsl:function name="tan:dateTime-to-decimal" as="xs:decimal*">
      <!-- Input: any number of ISO-compliant dates or dateTimes 
         Output: decimal between 0 and 1 that acts as a proxy for the date and time.
         These decimal values can then be sorted and compared.
         E.g., (2015-05-10) - > 0.2015051
         If input is not castable as a date or dateTime, 0 is returned
        -->
      <xsl:param name="time-or-dateTime" as="item()*"/>
      <xsl:for-each select="$time-or-dateTime">
         <xsl:variable name="utc" select="xs:dayTimeDuration('PT0H')"/>
         <xsl:variable name="dateTime" as="xs:dateTime?">
            <xsl:choose>
               <xsl:when test=". castable as xs:dateTime">
                  <xsl:value-of select="."/>
               </xsl:when>
               <xsl:when test=". castable as xs:date">
                  <xsl:value-of select="fn:dateTime(., xs:time('00:00:00'))"/>
               </xsl:when>
            </xsl:choose>
         </xsl:variable>
         <xsl:variable name="dt-adjusted-as-string"
            select="string(fn:adjust-dateTime-to-timezone($dateTime, $utc))"/>
         <xsl:value-of
            select="
               if (exists($dateTime)) then
                  number(concat('0.', replace(replace($dt-adjusted-as-string, '[-+]\d+:\d+$', ''), '\D+', '')))
               else
                  0"
         />
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:most-recent-dateTime" as="item()?">
      <!-- Input: a series of ISO-compliant date or dateTimes
         Output: the most recent one -->
      <xsl:param name="dateTimes" as="item()*"/>
      <xsl:variable name="decimal-val"
         select="
            for $i in $dateTimes
            return
               tan:dateTime-to-decimal($i)"/>
      <xsl:variable name="most-recent"
         select="
            if (exists($decimal-val)) then
               index-of($decimal-val, max($decimal-val))[1]
            else
               ()"/>
      <xsl:copy-of select="$dateTimes[$most-recent]"/>
   </xsl:function>

   <xsl:function name="tan:normalize-feature-test" as="xs:string*">
      <!-- Used to check for validity of @feature-test expressions; used to validate both 
            TAN-LM (class 2) and TAN-R-mor (class 3) files.
         Input: @feature-test string
         Output: @feature-test, normalized
      -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in $strings
            return
               normalize-space(replace($i, '([\(\),\|])', ' $1 '))"
      />
   </xsl:function>
   <xsl:function name="tan:normalize-text" as="xs:string*">
      <!-- Used to normalize a string before being checked for validity. Removes any help requested 
         and normalizes space -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in $text
            return
               normalize-space(replace($i, $help-trigger-regex, ''))"
      />
   </xsl:function>

   <!-- Functions that take regular expressions, to support TAN extensions -->
   <xsl:function name="tan:sequence-expand" as="xs:integer*">
      <!-- input: one string of concise TAN selectors (used by @pos, @char, @seg), 
            and one integer defining the value of 'last'
            output: a sequence of numbers representing the positions selected, unsorted, and retaining
            duplicate values.
            E.g., ("2 - 4, last-5 - last, 36", 50) -> (2, 3, 4, 45, 46, 47, 48, 49, 50, 36)
            Errors will be flagged as follows:
            0 = value that falls below 1
            -1 = value that surpasses the value of $max
            -2 = ranges that call for negative steps, e.g., '4 - 2'
        -->
      <xsl:param name="selector" as="xs:string?"/>
      <xsl:param name="max" as="xs:integer?"/>
      <!-- first normalize syntax -->
      <xsl:variable name="pass-1"
         select="replace(tan:normalize-text($selector), '(\d)\s*-\s*(last|all|max|\d)', '$1 - $2')"/>
      <xsl:variable name="pass-2" select="replace($pass-1, '(\d)\s+(\d)', '$1, $2')"/>
      <!-- replace 'last' with max value as string -->
      <xsl:variable name="selector-norm" select="replace($pass-2, 'last|all|max', string($max))"/>
      <xsl:variable name="seq-a" select="tokenize(normalize-space($selector-norm), '\s*,\s+')"/>
      <xsl:copy-of
         select="
            for $i in $seq-a
            return
               if (matches($i, ' - '))
               then
                  for $j in tan:string-subtract(tokenize($i, ' - ')[1], $max),
                     $k in tan:string-subtract(tokenize($i, ' - ')[2], $max)
                  return
                     if ($j gt $k) then
                        for $l in ($k to $j)
                        return
                           -2
                     else
                        ($j to $k)
               else
                  tan:string-subtract($i, $max)"
      />
   </xsl:function>
   <xsl:function name="tan:string-subtract" as="xs:integer?">
      <!-- input: string of pattern \d+(-\d+)? and a maximum value
        output: number giving the sum
        E.g., "50-5" -> 45
        Because this function is designed specifically for tan:sequence-expand(), any value above the maximum 
        will return -1, and any value below 1, 0 
      -->
      <xsl:param name="input" as="xs:string"/>
      <xsl:param name="max" as="xs:integer"/>
      <xsl:variable name="pass1" as="xs:integer?"
         select="
            xs:integer(if (matches($input, '\d+-\d+'))
            then
               number(tokenize($input, '-')[1]) - (number(tokenize($input, '-')[2]))
            else
               number($input))"/>
      <xsl:choose>
         <xsl:when test="$pass1 gt $max">
            <xsl:copy-of select="-1"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="max(($pass1, 0))"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:escape" as="xs:string*">
      <!-- Input: any sequence of strings; Output: each string prepared for regular expression searches,
        i.e., with reserved characters escaped out. -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in $strings
            return
               replace($i, concat('(', $regex-escaping-characters, ')'), '\\$1')"
      />
   </xsl:function>

   <xsl:function name="tan:duplicate-values" as="item()*">
      <!-- Input: any sequente of items
      Output: those items that appear in the sequence more than once
      This function parallels the standard fn:distinct-values()
      -->
      <xsl:param name="sequence" as="item()*"/>
      <xsl:copy-of select="$sequence[index-of($sequence, .)[2]]"/>
   </xsl:function>

   <xsl:function name="tan:has-property" as="xs:boolean">
      <!-- Input: any resolved TAN element, a sequence of strings with keyword names defined for that element by the standard TAN-key definitions, or an associated <key> -->
      <!-- Output: a boolean indicating whether the element has at least one IRI in common with the <item>s that either (1) have a <name> that matches one of the keywords (2nd parameter) or (2) are members of a <group> that has a name that matches one of the keywords -->
      <!-- This function is intended to allow an easy way to find out of  -->
      <xsl:param name="tan-element-with-IRI-children" as="element()"/>
      <xsl:param name="TAN-key-item-names" as="xs:string*"/>
      <xsl:variable name="element-items" as="element()*"
         select="
            for $i in $all-keywords
            return
               key('item-via-node-name', name($tan-element-with-IRI-children), $i)"/>
      <xsl:variable name="item-matches-by-name"
         select="$element-items[tan:name = $TAN-key-item-names]"/>
      <xsl:variable name="item-matches-by-IRI"
         select="$element-items[tan:IRI = $tan-element-with-IRI-children/tan:IRI]"/>
      <xsl:variable name="matched-item-group-names"
         select="
            for $i in $item-matches-by-IRI
            return
               $i/preceding::tan:group-type[@xml:id = tokenize($i/(@group, ancestor::tan:group/@type), '\s+')]"/>
      <xsl:variable name="matched-item-group-items" as="element()*">
         <xsl:for-each select="$item-matches-by-IRI">
            <xsl:variable name="group-ids" as="xs:string*"
               select="
                  for $i in (@group, ancestor::tan:group/@type)
                  return
                     tokenize($i, '\s+')"/>
            <xsl:copy-of select="root()//id($group-ids)"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="group-items"
         select="
            for $i in $all-keywords
            return
               key('item-via-node-name', 'group-type', $i)"/>
      <xsl:variable name="item-matches-by-group-name"
         select="$group-items[tan:name = $matched-item-group-names]"/>
      <xsl:choose>
         <xsl:when test="exists($item-matches-by-name)">
            <xsl:value-of
               select="$item-matches-by-name/tan:IRI = $tan-element-with-IRI-children/tan:IRI"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of
               select="$item-matches-by-group-name/tan:IRI = $tan-element-with-IRI-children/tan:IRI"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tan:has-relationship" as="xs:boolean">
      <!-- Input: a <see-also> element, a sequence of strings identifying names of keywords, and any extra
      TAN-key files you want to check, other than the standard TAN-key files.
      Output: boolean value specifying whether the <see-also> has a <relationship> that has the keyword defined
      This function will first check to see if IRIs in a <relationship> match, and if no IRIs are found then the check
      is performed on @which (against a <name> in the key definition).
      -->
      <xsl:param name="see-also-element" as="element()"/>
      <xsl:param name="keyword" as="xs:string*"/>
      <xsl:param name="extra-keys" as="document-node()*"/>
      <xsl:variable name="all-keys" select="$extra-keys, $TAN-keywords"/>
      <xsl:variable name="relationship-definitions"
         select="tan:get-attr-which-definition('relationship', $extra-keys, ())"/>
      <xsl:variable name="this-relationship-IRIs"
         select="$see-also-element/tan:relationship/tan:IRI"/>
      <xsl:variable name="this-relationship-attr-which"
         select="tan:normalize-text($see-also-element/tan:relationship/@which)"/>
      <xsl:value-of
         select="
            if (exists($this-relationship-IRIs)) then
               $this-relationship-IRIs = $relationship-definitions[tan:name = $keyword]/tan:IRI
            else
               $this-relationship-attr-which = $relationship-definitions[tan:name = $keyword and tan:name = $this-relationship-attr-which]"
      />
   </xsl:function>
   <xsl:function name="tan:get-attr-which-definition" as="element()*">
      <!-- one-parameter version of the master one, below -->
      <xsl:param name="element-that-takes-attribute-which" as="item()"/>
      <xsl:copy-of
         select="tan:get-attr-which-definition($element-that-takes-attribute-which, $keys-1st-da, ())"
      />
   </xsl:function>
   <xsl:function name="tan:get-attr-which-definition" as="element()*">
      <!-- Input: any element that has @which (or a string value of an element that takes @which); any TAN-key 
         documents other than the standard TAN ones; and an optional name that restricts the search to a particular group
         Output: the tan:items that are valid keywords for the element in question
      -->
      <xsl:param name="element-that-takes-attribute-which" as="item()"/>
      <xsl:param name="extra-TAN-key-docs" as="document-node()*"/>
      <xsl:param name="group-name-filter" as="xs:string?"/>
      <xsl:variable name="element-name" as="xs:string?"
         select="
            if ($element-that-takes-attribute-which instance of xs:string) then
               $element-that-takes-attribute-which
            else
               name($element-that-takes-attribute-which)"/>
      <xsl:variable name="all-TAN-key-docs" select="$extra-TAN-key-docs, $TAN-keywords"/>
      <xsl:copy-of
         select="
            for $i in $all-TAN-key-docs
            return
               key('item-via-node-name', $element-name, $i)[if (string-length($group-name-filter) gt 0) then
                  (ancestor::tan:group/tan:name = $group-name-filter)
               else
                  true()]"
      />
   </xsl:function>

   <xsl:function name="tan:must-refer-to-external-tan-file" as="xs:boolean">
      <!-- Input: node in a TAN document. 
         Output: boolean value indicating whether the node or its parent must name or refer to a TAN file. -->
      <xsl:param name="node" as="node()"/>
      <xsl:variable name="class-2-elements-that-must-always-refer-to-tan-files" select="('source')"/>
      <xsl:variable name="this-class" select="tan:class-number($node)"/>
      <xsl:value-of
         select="
            if (
            ((name($node),
            name($node/parent::node())) = $elements-that-must-always-refer-to-tan-files)
            or ($node[(tan:relationship,
            preceding-sibling::tan:relationship) = $relationship-keywords-for-tan-files])
            or ((((name($node),
            name($node/parent::node())) = $class-2-elements-that-must-always-refer-to-tan-files)
            )
            and $this-class = 2)
            )
            then
               true()
            else
               false()"
      />
   </xsl:function>

   <xsl:function name="tan:q-ref" as="xs:string*">
      <!-- Input: any elements
      Output: the q-ref of those elements; a q-ref is defined as a concatenated string  consisting of, for
      each ancestor and self, the name plus the number indicating which sibling it is of that type of element.  
      This function is useful when trying to correlate an unbreadmarked file (an original TAN file) against
      its breadcrumbed counterpart (e.g., $self-resolved), to be able to check for errors. If any
      changes in element names, e.g., TEI - > TAN-T, are made during the standard preparation process, those
      changes are made here as well.
      -->
      <xsl:param name="elements" as="element()*"/>
      <xsl:for-each select="$elements">
         <xsl:variable name="pass1" as="xs:string*">
            <xsl:for-each select="ancestor-or-self::*">
               <xsl:variable name="this-name" select="name()"/>
               <xsl:copy-of
                  select="
                     if ($this-name = 'TEI') then
                        'TAN-T'
                     else
                        $this-name"/>
               <xsl:copy-of
                  select="
                     if (exists(@q)) then
                        @q
                     else
                        string(count(preceding-sibling::*[name(.) = $this-name]) + 1)"
               />
            </xsl:for-each>
         </xsl:variable>
         <xsl:value-of select="string-join($pass1, ' ')"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:element-to-comment" as="comment()">
      <xsl:param name="element" as="element()*"/>
      <xsl:comment>
            <xsl:sequence select="$element"/>
        </xsl:comment>
   </xsl:function>


   <!-- TRANSFORMATIVE TEMPLATES -->

   <!-- Default templates, shared across modes -->
   <xsl:template match="node()"
      mode="resolve-href include resolve-attr-include resolve-keyword arabic-numerals strip-duplicates">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <!-- Mode-specific templates -->
   <xsl:template match="/*" mode="first-stamp">
      <!-- The first-stamp mode ensures that when a document is handed over to a variable,
      the original document URI is not lost. It also provides (1) the breadcrumbing service, so that
      errors occurring downstream, in an inclusion or TAN-key file can be diagnosed, and (2) the option
      for @src to be imprinted on the root element, so that a class 1 TAN file can be tethered to a 
      class 2 file that uses it as a source.-->
      <xsl:param name="leave-breadcrumbs" as="xs:boolean?"/>
      <xsl:param name="stamp-root-element-with-attr-name" as="xs:string?"/>
      <xsl:param name="stamp-root-element-with-attr-val" as="xs:string?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(exists(@base-uri))">
            <xsl:attribute name="base-uri" select="base-uri(.)"/>
         </xsl:if>
         <xsl:if
            test="string-length($stamp-root-element-with-attr-name) gt 0 and string-length($stamp-root-element-with-attr-val) gt 0">
            <xsl:attribute name="{$stamp-root-element-with-attr-name}"
               select="$stamp-root-element-with-attr-val"/>
         </xsl:if>
         <xsl:if test="$leave-breadcrumbs = true()">
            <xsl:attribute name="q" select="1"/>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="$leave-breadcrumbs = true()">
               <xsl:apply-templates mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="node()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="node()" mode="first-stamp">
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="q"
            select="count(preceding-sibling::*[name() = $this-element-name]) + 1"/>
         <!--<xsl:if test="not(parent::*)">
            <xsl:attribute name="uri" select="base-uri(.)"/>
         </xsl:if>-->
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:strip-duplicates" as="document-node()*">
      <xsl:param name="tan-docs" as="document-node()*"/>
      <xsl:param name="element-names-to-check" as="xs:string*"/>
      <xsl:for-each select="$tan-docs">
         <xsl:copy>
            <xsl:apply-templates mode="strip-duplicates">
               <xsl:with-param name="element-names-to-check" select="$element-names-to-check"
                  tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:* | tei:*" mode="strip-duplicates">
      <xsl:param name="element-names-to-check" as="xs:string*" tunnel="yes"/>
      <xsl:choose>
         <xsl:when test="name(.) = $element-names-to-check">
            <xsl:if
               test="
                  every $i in preceding-sibling::*
                     satisfies not(deep-equal(., $i))">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:apply-templates mode="#current"/>
               </xsl:copy>
            </xsl:if>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="*[@include]" mode="resolve-attr-include">
      <xsl:param name="tan-doc-ids-checked-so-far" as="xs:string*" tunnel="yes"/>
      <xsl:param name="docs-whence-inclusion-resolved" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-element-name" select="name($this-element)"/>
      <xsl:variable name="these-inclusion-idrefs"
         select="tokenize(tan:normalize-text(@include), ' ')"/>
      <xsl:variable name="relevant-docs"
         select="$docs-whence-inclusion-resolved[*/@inclusion = $these-inclusion-idrefs]"
         as="document-node()*"/>
      <xsl:variable name="relevant-doc-ids" select="$relevant-docs/*/@id"/>
      <xsl:variable name="relevant-elements-to-include"
         select="$relevant-docs//*[name() = $this-element-name][not(ancestor::*[name() = $this-element-name])]"/>
      <xsl:variable name="attr-in-this-element-to-suppress" select="'include'"/>
      <xsl:variable name="attr-in-included-element-to-suppress" select="('ed-when', 'ed-who', 'which')"/>
      <!--<xsl:variable name="fetched-elements" select="tan:get-elements($this-element, (), ())" as="element()*"/>-->
      <!--<xsl:variable name="ambiguous-numeral-types"
         select="
            tan:analyze-attr-n-or-ref-numerals($fetched-elements, if (name($this-element) = 'div') then
               'type'
            else
               (), true(), false())"
         as="element()*"/>-->
      <!--<xsl:variable name="roman-numerals-before-alphabetic"
         select="
            if ($ambiguous-numeral-types/@type-a gt $ambiguous-numeral-types/@type-i) then
               false()
            else
               true()"
      />-->
      <!--<xsl:variable name="fetched-elements-norm" as="element()*">
         <xsl:apply-templates select="$fetched-elements" mode="arabic-numerals">
            <xsl:with-param name="ambiguous-numeral-types" select="$ambiguous-numeral-types" tunnel="yes"/>
         </xsl:apply-templates>
         <!-\-<xsl:choose>
            <xsl:when test="exists($ambiguous-numeral-types)">
               <xsl:apply-templates select="$fetched-elements" mode="arabic-numerals">
                  <xsl:with-param name="ambiguous-numeral-types" select="$ambiguous-numeral-types" tunnel="yes"/>
                  <!-\\-<xsl:with-param name="treat-ambiguous-a-or-i-type-as-roman-numeral"
                     select="$roman-numerals-before-alphabetic" tunnel="yes"/>-\\->
                  <!-\\-<xsl:with-param name="warn-on-ambiguous-numerals" tunnel="yes"
                     select="
                        if (exists($rom-vs-aaa-numerals/@type-a) and exists($rom-vs-aaa-numerals/@type-i)) then
                           true()
                        else
                           false()"
                  />-\\->
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$fetched-elements"/>
            </xsl:otherwise>
         </xsl:choose>-\->
      </xsl:variable>-->
      <xsl:choose>
         <xsl:when test="not(exists($relevant-docs))">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="tan:error('tan05')"/>
               <!--<test><xsl:value-of select="$these-inclusion-idrefs"/></test>-->
               <!--<test>
                  <xsl:copy-of select="$docs-whence-inclusion-resolved"/>
               </test>-->
               <!--<test><xsl:copy-of select="$docs-whence-inclusion-resolved/*/*/@*"/></test>-->
               <!--<test>oops, relevant doc doesn't exist <xsl:value-of select="for $i in $docs-whence-inclusion-resolved return name($i/*)"/></test>-->
            </xsl:copy>
         </xsl:when>
         <xsl:when test="exists($relevant-docs/(tan:error, tan:fatal))">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$relevant-docs/*"/>
            </xsl:copy>
         </xsl:when>
         <xsl:when test="$tan-doc-ids-checked-so-far = $relevant-doc-ids">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="tan:error('inc03')"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <!--<test><xsl:copy-of select="$relevant-docs"/></test>-->
            <xsl:for-each select="$relevant-elements-to-include">
               <xsl:copy>
                  <xsl:copy-of select="$this-element/@*[not(name() = $attr-in-this-element-to-suppress)]"/>
                  <xsl:for-each select="$this-element/@*[name() = $attr-in-this-element-to-suppress]">
                     <xsl:attribute name="orig-{name()}" select="."/>
                  </xsl:for-each>
                  <!-- We bring from the inclusion document only those attributes that have any meaning in the new document (e.g., @ed-when and @ed-who are skipped), and those attributes that are ambiguous outside their host context are normalized (@n and @ref are converted to Arabic numerals) -->
                  <xsl:copy-of select="@*[not(name() = $attr-in-included-element-to-suppress)]"/>
                  <xsl:for-each select="@*[name() = $attr-in-included-element-to-suppress]">
                     <xsl:attribute name="orig-{name()}" select="."/>
                  </xsl:for-each>
                  <!--<xsl:copy-of select="@*[not(name(.) = ('ed-when', 'ed-who', 'which'))]"/>-->
                  <xsl:copy-of select="node()"/>
                  <!--<test>success</test>-->
                  <!-- We do not apply templates again, because every */@include is (or should be) empty -->
               </xsl:copy>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:function name="tan:analyze-elements-with-numeral-attributes" as="element()*">
      <!-- Input: any sequence of elements that contain (either in themselves or their descendants) @n, @old, or @ref; an optional string indicating an element whose tokenized value should be used as a basis for grouping the results; two booleans indicating whether only ambiguous types should be checked and whether the analysis should be performed only shallowly (i.e., not on any descendants of the input elements) -->
      <!-- Output: zero or more <ns>s (one per group, and with @type-i, @type-a, and type-i-or-a if only ambiguous types are intended), each with one or more <n>s (one per atomic value in @n or @ref of the group picked), each with one or more <val type="[i, 1, 1a, a, a1, or $, depending on the type]">[VALUE]</val>, where VALUE is what the item is when converted  -->
      <!-- This function is used to help other functions determine whether there is an error, or how ambiguous numerals should be interpreted -->
      <xsl:param name="elements" as="node()*"/>
      <xsl:param name="group-by-what-attr-value" as="xs:string?"/>
      <xsl:param name="analyze-only-ambiguous-types" as="xs:boolean"/>
      <xsl:param name="shallow-analysis" as="xs:boolean"/>
      <xsl:variable name="elements-to-analyze"
         select="
            (if ($shallow-analysis = true()) then
               $elements
            else
               $elements//*)[@ref or @n or @old]"/>
      <xsl:for-each-group select="$elements-to-analyze"
         group-by="
            if (string-length($group-by-what-attr-value) gt 0) then
               tokenize(tan:normalize-text(@*[name() = $group-by-what-attr-value]), ' ')
            else
               true()">
         <xsl:variable name="analysis" as="element()*">
            <xsl:for-each
               select="
                  for $i in tan:normalize-text(current-group()/(@ref, @n, @old))
                  return
                     tokenize($i, ' ')">
               <n>
                  <xsl:choose>
                     <xsl:when test="$analyze-only-ambiguous-types = false()">
                        <xsl:choose>
                           <xsl:when test="matches(., $n-type-pattern[2], 'i')">
                              <val type="{$n-type[2]}">
                                 <xsl:value-of select="."/>
                              </val>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:if test="matches(., $n-type-pattern[1], 'i')">
                                 <val type="{$n-type[1]}">
                                    <xsl:value-of select="tan:rom-to-int(.)"/>
                                 </val>
                              </xsl:if>
                              <xsl:if test="matches(., $n-type-pattern[3], 'i')">
                                 <val type="{$n-type[3]}">
                                    <xsl:value-of
                                       select="concat(replace(., '\D+', ''), '-', tan:aaa-to-int(replace(., '\d+', '')))"
                                    />
                                 </val>
                              </xsl:if>
                              <xsl:if test="matches(., $n-type-pattern[4], 'i')">
                                 <val type="{$n-type[4]}">
                                    <xsl:value-of select="tan:aaa-to-int(.)"/>
                                 </val>
                              </xsl:if>
                              <xsl:if test="matches(., $n-type-pattern[5], 'i')">
                                 <val type="{$n-type[5]}">
                                    <xsl:value-of
                                       select="concat(tan:aaa-to-int(replace(., '\d+', '')), '-', replace(., '\D+', ''))"
                                    />
                                 </val>
                              </xsl:if>
                              <val type="$">
                                 <xsl:value-of select="lower-case(.)"/>
                              </val>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:if test="matches(., $n-type-pattern[1], 'i')">
                           <val type="{$n-type[1]}">
                              <xsl:value-of select="tan:rom-to-int(.)"/>
                           </val>
                        </xsl:if>
                        <xsl:if test="matches(., $n-type-pattern[4], 'i')">
                           <val type="{$n-type[4]}">
                              <xsl:value-of select="tan:aaa-to-int(.)"/>
                           </val>
                        </xsl:if>
                        <val type="$">
                           <xsl:value-of select="."/>
                        </val>
                     </xsl:otherwise>
                  </xsl:choose>
               </n>
               <!--<xsl:for-each
                  select="tokenize(., ' ')[matches(., concat($n-type-pattern[4], '|', $n-type-pattern[1]), 'i')]">
                  <xsl:variable name="this-item" select="lower-case(.)"/>
                  <xsl:choose>
                     <xsl:when test="not(matches($this-item, $n-type-pattern[4]))">
                        <xsl:value-of select="$n-type[1]"/>
                     </xsl:when>
                     <xsl:when test="not(matches($this-item, $n-type-pattern[1]))">
                        <xsl:value-of select="$n-type[4]"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:value-of select="concat('i-or-a#',$this-item)"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>-->
            </xsl:for-each>
         </xsl:variable>
         <!--<xsl:variable name="ambiguous-vals" as="xs:string*"
            select="
               for $i in $pass1[matches(., 'i-or-a#')]
               return
                  replace($i, 'i-or-a#', '')"/>-->
         <xsl:if test="exists($analysis)">
            <ns>
               <xsl:if test="string-length($group-by-what-attr-value) gt 0">
                  <xsl:attribute name="{$group-by-what-attr-value}" select="current-grouping-key()"
                  />
               </xsl:if>
               <xsl:if test="$analyze-only-ambiguous-types = true()">
                  <xsl:variable name="ambiguous-analyses"
                     select="$analysis[tan:val/@type = $n-type[1] and tan:val/@type = $n-type[4]]"/>
                  <xsl:variable name="ambiguous-analyses-count" select="count($ambiguous-analyses)"/>
                  <xsl:variable name="this-i-count"
                     select="count($analysis[tan:val/@type = $n-type[1]]) - $ambiguous-analyses-count"/>
                  <xsl:variable name="this-a-count"
                     select="count($analysis[tan:val/@type = $n-type[4]]) - $ambiguous-analyses-count"/>
                  <xsl:attribute name="type-i" select="$this-i-count"/>
                  <xsl:attribute name="type-a" select="$this-a-count"/>
                  <xsl:attribute name="type-i-or-a" select="$ambiguous-analyses-count"/>
                  <xsl:attribute name="type-i-or-a-is-probably">
                     <xsl:choose>
                        <xsl:when test="$this-i-count lt 1 and $this-a-count gt 0">a</xsl:when>
                        <xsl:when test="$this-a-count lt 1 and $this-i-count gt 0">i</xsl:when>
                        <xsl:otherwise>
                           <xsl:choose>
                              <xsl:when
                                 test="
                                    every $i in $ambiguous-analyses/tan:val[@type = '$']
                                       satisfies string-length($i) le 1"
                                 >a</xsl:when>
                              <xsl:otherwise>i</xsl:otherwise>
                           </xsl:choose>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:attribute>
               </xsl:if>
               <xsl:copy-of select="$analysis"/>
               <!--<xsl:for-each-group select="$pass1" group-by=".">
                  <xsl:attribute name="type-{replace(current-grouping-key(),'#.+$','')}"
                     select="count(current-group())"/>
               </xsl:for-each-group>-->
               <!--<xsl:if test="exists($ambiguous-vals)">
                  <xsl:attribute name="i-or-a-vals" select="$ambiguous-vals"/>
               </xsl:if>-->
            </ns>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:function>

   <!--<xsl:function name="tan:resolve-doc-keywords" as="document-node()*">
      <!-\- Input: any number of TAN documents and optionally a sequence of strings representing ids 
         that should be imprinted into the root element of each document as @src
         Output: those same documents, with @src imprinted, and all instances of @which resolved
         to their correct name + IRI elements.
      -\->
      <xsl:param name="tan-docs" as="document-node()*"/>
      <xsl:param name="src-ids" as="xs:string*"/>
      <xsl:for-each select="$tan-docs">
         <xsl:copy>
            <xsl:variable name="pos" select="position()"/>
            <xsl:apply-templates mode="resolve-keyword">
               <xsl:with-param name="src-id" select="$src-ids[$pos]" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:resolve-keyword" as="element()*">
      <!-\- one-parameter version of the next -\->
      <xsl:param name="tan-element" as="element()*"/>
      <xsl:copy-of select="tan:resolve-keyword($tan-element, ())"/>
   </xsl:function>
   <xsl:function name="tan:resolve-keyword" as="node()*">
      <!-\- Same as tan:resolve-doc-keywords(), but applicable to elements -\->
      <xsl:param name="tan-node" as="node()*"/>
      <xsl:param name="src-ids" as="xs:string*"/>
      <xsl:for-each select="$tan-node">
         <xsl:variable name="pos" select="position()"/>
         <xsl:apply-templates select="." mode="resolve-keyword">
            <xsl:with-param name="src-id" select="$src-ids[$pos]" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:for-each>
   </xsl:function>-->

   <xsl:template match="tei:*[@which] | tan:*[@which]" mode="resolve-keyword">
      <xsl:param name="extra-keys" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="element-name" select="name(.)"/>
      <xsl:variable name="this-which" select="tan:normalize-text(@which)"/>
      <xsl:variable name="help-requested" select="matches(@which, $help-trigger-regex)"/>
      <xsl:variable name="attr-in-key-element-to-suppress" select="('group')" as="xs:string*"/>
      <xsl:variable name="valid-definitions"
         select="tan:get-attr-which-definition(., $extra-keys, ())"/>
      <xsl:variable name="definition-matches" as="element()*"
         select="$valid-definitions[tan:name = $this-which]"/>
      <xsl:variable name="close-matches"
         select="$valid-definitions[tan:name[matches(., $this-which)]]"/>
      <xsl:variable name="best-matches"
         select="
            if (exists($close-matches))
            then
               $close-matches
            else
               $valid-definitions"/>
      <xsl:variable name="definition-groups"
         select="normalize-space(string-join(($definition-matches/@group, $definition-matches/ancestor::tan:group/@type), ' '))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$definition-matches/tan:token-definition/@regex"/>
         <xsl:copy-of select="$definition-matches/@*[not(name() = $attr-in-key-element-to-suppress)]"/>
         <xsl:for-each select="$definition-matches/@*[name() = $attr-in-key-element-to-suppress]">
            <xsl:attribute name="orig-{name()}" select="."/>
         </xsl:for-each>
         <xsl:if test="exists($definition-groups)">
            <!-- although strictly not necessary for validation, the <group> of a keyword is enormously helpful in later processing, so the name of each group is included here -->
            <xsl:attribute name="orig-group" select="$definition-groups"/>
         </xsl:if>
         <xsl:if test="not(exists($definition-matches))">
            <xsl:variable name="this-message" as="xs:string*">
               <xsl:for-each select="$best-matches">
                  <xsl:value-of select="tan:name[1]"/>
                  <xsl:if test="tan:name[2]">
                     <xsl:value-of
                        select="concat(' (', string-join(tan:name[position() gt 1], '; '), ')')"/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:variable>
            <xsl:copy-of
               select="tan:error('whi01', concat('Try: ', string-join($this-message, '; ')), $best-matches)"
            />
         </xsl:if>
         <xsl:if test="count($definition-matches) gt 1">
            <xsl:copy-of select="tan:error('whi02')"/>
         </xsl:if>
         <xsl:if test="not(exists($valid-definitions))">
            <xsl:copy-of select="tan:error('whi03')"/>
         </xsl:if>
         <xsl:if test="($help-requested = true()) and exists($definition-matches)">
            <xsl:variable name="this-message" as="xs:string*">
               <xsl:text>Help: </xsl:text>
               <xsl:for-each select="$definition-matches">
                  <xsl:text>ITEM </xsl:text>
                  <xsl:value-of select="tan:name[1]"/>
                  <xsl:text> </xsl:text>
                  <xsl:if test="tan:name[2]">
                     <xsl:value-of
                        select="concat('(', string-join(tan:name[position() gt 1], '; '), ') ')"/>
                  </xsl:if>
                  <xsl:text>description: </xsl:text>
                  <xsl:value-of select="tan:desc"/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:copy-of select="tan:help($this-message, $valid-definitions)"/>
         </xsl:if>
         <xsl:copy-of select="$definition-matches/*[not(self::tan:token-definition)]"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="*[@href]" mode="resolve-href first-stamp">
      <xsl:param name="special-base-uri" as="xs:string?" tunnel="yes"/>
      <xsl:variable name="this-base-uri"
         select="
            if (exists($special-base-uri)) then
               $special-base-uri
            else
               tan:base-uri(.)"/>
      <xsl:variable name="resolved-href" select="resolve-uri(@href, $this-base-uri)"/>
      <xsl:copy>
         <xsl:copy-of select="@* except @href"/>
         <xsl:attribute name="href">
            <xsl:value-of select="$resolved-href"/>
         </xsl:attribute>
         <xsl:if test="not(@href = $resolved-href)">
            <xsl:attribute name="orig-href" select="@href"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="comment() | processing-instruction()"
      mode="strip-all-attributes-except strip-specific-attributes strip-text">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="*" mode="strip-all-attributes-except">
      <xsl:param name="attributes-to-keep" as="xs:string+" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*[name(.) = $attributes-to-keep]"/>
         <xsl:apply-templates mode="strip-all-attributes-except"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*" mode="strip-specific-attributes">
      <xsl:param name="attributes-to-strip" as="xs:string+" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*[not(name(.) = $attributes-to-strip)]"/>
         <xsl:apply-templates mode="strip-specific-attributes"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*" mode="strip-text">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="* | comment() | processing-instruction()" mode="strip-text"/>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
