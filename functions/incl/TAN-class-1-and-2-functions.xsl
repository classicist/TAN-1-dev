<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>Jan 24, 2017</xd:p>
         <xd:p>Core variables and functions for class 1 and 2 TAN files (i.e., not applicable to
            class 3 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:variable name="tokenization-nonspace"
      select="$token-definitions-reserved[following-sibling::tan:name = 'nonspace']"/>

   <!-- RESOLVING CLASS 1 DOCUMENTS -->
   <xsl:template match="*[@n and not(@orig-n)]" mode="arabic-numerals">
      <!-- The companion <xsl:template> to this, treating *[@ref], is in TAN-class-2-functions -->
      <!--<xsl:param name="treat-ambiguous-a-or-i-type-as-roman-numeral" as="xs:boolean?" tunnel="yes"/>-->
      <!--<xsl:param name="warn-on-ambiguous-numerals" as="xs:boolean?" tunnel="yes"/>-->
      <xsl:param name="ambiguous-numeral-types" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-type" select="tan:normalize-text(@type)"/>
      <xsl:variable name="this-amb-num-type" select="$ambiguous-numeral-types[@type = $this-type]" as="element()*"/>
      <xsl:variable name="this-n-norm" select="tan:normalize-text(lower-case(@n))"/>
      <xsl:variable name="this-n-analyzed" as="element()"
         select="tan:analyze-elements-with-numeral-attributes(., (), false(), true())"/>
      <xsl:variable name="this-n-identified" as="element()">
         <xsl:apply-templates select="$this-n-analyzed" mode="#current">
            <xsl:with-param name="this-amb-num-type" select="$this-amb-num-type" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <!-- Does the div have an @n value that is one or more numerals, no strings? -->
      <xsl:variable name="is-complex"
         select="count($this-n-identified//tan:val) gt 1 and not(exists($this-n-identified//tan:val[@type = '$']))"
         as="xs:boolean"/>
      <xsl:variable name="this-n-norm-string" as="xs:string?"
         select="string-join($this-n-identified//text(), '')"/>
      <xsl:variable name="this-n-norm-expanded" as="xs:string?">
         <xsl:variable name="pass1" as="xs:string*">
            <xsl:analyze-string select="$this-n-identified" regex="\d+-\d+">
               <xsl:matching-substring>
                  <xsl:variable name="digits" select="tokenize(.,'-')"/>
                  <xsl:variable name="range" as="xs:integer*" select="xs:integer($digits[1]) to xs:integer($digits[2])"/>
                  <xsl:value-of
                     select="
                        string-join(for $i in ($range)
                        return
                           string($i), ' ')"
                  />
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="."/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <xsl:value-of select="string-join($pass1, '')"/>
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(@n = $this-n-norm-expanded)">
            <xsl:attribute name="orig-n" select="@n"/>
            <xsl:attribute name="n" select="$this-n-norm-expanded"/>
         </xsl:if>
         <xsl:if test="$is-complex = true()">
            <xsl:attribute name="complex"/>
         </xsl:if>
         <xsl:if test="matches($this-n-norm-expanded, '\*')">
            <xsl:copy-of select="tan:error('tan12')"/>
         </xsl:if>
         <xsl:if
            test="number($this-amb-num-type/@type-i) gt 0 and number($this-amb-num-type/@type-a) gt 0">
            <xsl:copy-of
               select="tan:error('cl114', concat($this-n-norm, ' interpreted as ', $this-n-norm-expanded, '; all @n values for this div type: ', string-join(distinct-values($this-amb-num-type//tan:val[@type = '$']), ' ')))"
            />
         </xsl:if>
         <!--<test>
            <xsl:copy-of select="$this-n-identified"/>
         </test>-->
         <xsl:apply-templates mode="arabic-numerals"/>
      </xsl:copy>
      <xsl:if test="$is-complex = true()">
         <xsl:for-each select="tokenize($this-n-norm-expanded,' ')">
            <div>
               <xsl:copy-of select="$this-element/(@* except @n)"/>
               <xsl:attribute name="n" select="."/>
               <xsl:attribute name="see" select="$this-n-norm-expanded"/>
            </div>
         </xsl:for-each>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tan:n" mode="arabic-numerals">
      <xsl:param name="this-amb-num-type" as="element()?" tunnel="yes"/>
      <xsl:copy>
         <xsl:choose>
         <xsl:when test="tan:val/@type = $n-type[1] and tan:val/@type = $n-type[4]">
            <xsl:choose>
               <xsl:when test="$this-amb-num-type/@type-i-or-a-is-probably = 'a'">
                  <!-- it's probably an alphabetic not Roman numeral -->
                  <xsl:copy-of select="(tan:val[not(@type = $n-type[1])])[1]"/>
               </xsl:when>
               <xsl:when test="$this-amb-num-type/@type-i-or-a-is-probably = 'i'">
                  <!-- it's probably a Roman not alphabetic numeral -->
                  <xsl:copy-of select="(tan:val[not(@type = $n-type[4])])[1]"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="tan:val[1]"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <!-- no ambiguity; just use the first value -->
            <xsl:copy-of select="tan:val[1]"/>
         </xsl:otherwise>
      </xsl:choose>
      </xsl:copy>
   </xsl:template>

   <!-- TEXT FUNCTIONS -->

   <xsl:variable name="zwj" select="'&#x200D;'"/>
   <xsl:variable name="soft-hyphen" select="'&#xAD;'"/>
   <xsl:variable name="special-end-div-chars" select="($zwj, $soft-hyphen)" as="xs:string+"/>
   <xsl:variable name="special-end-div-chars-regex"
      select="concat('[', string-join($special-end-div-chars, ''), ']$')" as="xs:string"/>
   <xsl:variable name="char-reg-exp" select="'\P{M}\p{M}*'"/>

   <xsl:function name="tan:chop-string" as="xs:string*">
      <!-- Input: any string -->
      <!-- Output: that string chopped into a sequence of strings, following TAN rules about modifying characters -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:if test="string-length($input) gt 0">
         <xsl:analyze-string select="$input" regex="{$char-reg-exp}">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:if>
   </xsl:function>
   <xsl:function name="tan:string-length" as="xs:integer">
      <!-- Input: any string -->
      <!-- Output: the number of characters in the string, as defined by TAN (i.e., modifiers are counted with the preceding base character) -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:copy-of select="count(tan:chop-string($input))"/>
   </xsl:function>
   <xsl:function name="tan:text-join" as="xs:string">
      <xsl:param name="items" as="item()*"/>
      <xsl:copy-of select="tan:text-join($items, true())"/>
   </xsl:function>
   <xsl:function name="tan:text-join" as="xs:string">
      <!-- Input: any number of elements, text nodes, or strings; a boolean indicating whether the end of the sequence should also be prepared -->
      <!-- Output: a single string that joins and normalizes them according to TAN rules: if the item is (1) a <tok> or <non-tok> that has following siblings or (2) the last leaf element and $prep-end is false then the bare text is used; otherwise the text return follows the rules of tan:normalize-div-text() --> 
      <!-- If the second parameter is true, then the end of the resultant string is checked for special div-end characters -->
      <xsl:param name="items" as="item()*"/>
      <xsl:param name="prep-end" as="xs:boolean"/>
      <xsl:variable name="item-count" select="count($items)"/>
      <xsl:variable name="string-sequence" as="xs:string*">
         <xsl:for-each select="$items">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="leaf-divs" select="descendant-or-self::*:div[not(*:div)]"/>
            <xsl:choose>
               <xsl:when test="exists($leaf-divs)">
                  <xsl:for-each select="$leaf-divs">
                     <xsl:variable name="pos2" select="position()"/>
                     <xsl:variable name="tok-children" select="(tan:tok, tan:non-tok)"/>
                     <xsl:variable name="this-text" select="if (exists($tok-children)) then $tok-children/text() else text()"/>
                     <xsl:variable name="child-text" select="string-join($this-text, '')"/>
                     <xsl:choose>
                        <xsl:when test="$pos = $item-count and $pos2 = count($leaf-divs) and $prep-end = false()">
                           <xsl:value-of select="normalize-space($child-text)"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:value-of select="tan:normalize-div-text($child-text)"/>
                        </xsl:otherwise>
                     </xsl:choose>
                     
                  </xsl:for-each>
               </xsl:when>
               <xsl:when test="self::tan:tok or self::tan:non-tok">
                  <xsl:value-of select="replace(., '\s+', ' ')"/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- The item doesn't have leaf divs, and it isn't a <tok> or <non-tok>. Who knows what it is, so we just normalize the text -->
                  <xsl:value-of select="tan:normalize-div-text(.)"/>
               </xsl:otherwise>
            </xsl:choose>
            <!--<xsl:choose>
               <xsl:when test=". instance of xs:string">
                  <xsl:value-of select="tan:normalize-div-text(.)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:for-each select="descendant-or-self::*[self::tan:tok or self::tan:non-tok or not(*)]">
                     <xsl:choose>
                        <xsl:when test="name() = ('tok', 'non-tok')">
                           <!-\- many <non-tok> elements will have nothing but space, so normalize-text() is self-defeating -\->
                           <xsl:value-of select="replace(., '\s+', ' ')"/>
                        </xsl:when>
                        <xsl:when test="$pos = $item-count and $prep-end = false()">
                           <xsl:value-of select="normalize-space(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:value-of select="tan:normalize-div-text(.)"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each>
               </xsl:otherwise>
            </xsl:choose>-->
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($string-sequence, '')"/>
   </xsl:function>

   <xsl:function name="tan:normalize-div-text" as="xs:string*">
      <!-- Input: any sequence of strings -->
      <!-- Output: the same sequence, normalized according to TAN rules. Each item in the sequence is space normalized and then if its end matches one of the special div-end characters, ZWJ U+200D or SOFT HYPHEN U+AD, the character is removed; otherwise a space is added at the end. Zero-length strings are skipped. -->
      <!-- This function is designed specifically for TAN's commitment to nonmixed content. That is, every TAN element contains either elements or non-whitespace text but not both, which also means that whitespace text nodes are effectively ignored. It is assumed that every TAN element is followed by a notional whitespace. -->
      <xsl:param name="div-strings" as="xs:string*"/>
      <xsl:for-each select="$div-strings">
         <xsl:variable name="this-norm" select="normalize-space(.)"/>
         <xsl:choose>
            <xsl:when test="matches($this-norm, $special-end-div-chars-regex)">
               <xsl:value-of select="replace($this-norm, $special-end-div-chars-regex, '')"/>
            </xsl:when>
            <xsl:when test="string-length(.) lt 1"/>
            <xsl:otherwise>
               <xsl:value-of select="concat($this-norm, ' ')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <!-- PREPARATION -->

   <xsl:function name="tan:prep-resolved-class-1-doc" as="document-node()*">
      <!-- Input: sequence of resolved class 1 TAN documents 
         Output: sequence of documents with these changes:
         /*   - >   add @work = "[DIGIT TAKEN FROM TAN-A-div //tan:group[tan:work]/@id]"
         tei:TEI - > tan:TAN-T
         tei:text/tei:body   - >   tan:body
         tei:div  - >  tan:div
         <div [copy of @*] ref="[NORMALIZED, FLAT REF WITH N SUBSTITUTIONS AND SUPPRESSIONS]">[COPY OF TEXT][SECOND COPY INSIDE TEI MARKUP, IF ANY]</div>
         Text remains untokenized. Any <div> with an @n with a range will be replicated as it is, but will be followed by empty <div>s with simple forms of @n and a @see that points to the ref of the original  -->
      <xsl:param name="class-2-expanded-2" as="document-node()?"/>
      <xsl:param name="resolved-class-1-documents" as="document-node()*"/>
      <xsl:for-each select="$resolved-class-1-documents">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:variable name="pos" select="position()"/>
         <xsl:copy>
            <xsl:apply-templates mode="prep-class-1" select="node()">
               <xsl:with-param name="key-to-this-src" tunnel="yes"
                  select="
                     $class-2-expanded-2/*/(tan:head/tan:declarations/tan:*[@src = $this-src],
                     tan:body)"
               />
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="prep-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-T | tei:TEI" mode="prep-class-1">
      <!-- Homogenize tei:TEI to tan:TAN-T -->
      <xsl:param name="key-to-this-src" as="element()*" tunnel="yes"/>
      <xsl:variable name="src-id" select="@src"/>
      <TAN-T>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="work"
            select="($key-to-this-src/tan:group[tan:work/@src = $src-id]/@n, 1)[1]"/>
         <xsl:apply-templates mode="#current"> </xsl:apply-templates>
      </TAN-T>
   </xsl:template>
   <xsl:template match="tei:body" mode="prep-class-1">
      <body>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </body>
   </xsl:template>
   <xsl:template match="tei:text" mode="prep-class-1">
      <!-- Makes sure the tei:body rises rootward one level, as is customary in TAN and HTML -->
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template match="tan:div | tei:div" mode="prep-class-1">
      <xsl:param name="key-to-this-src" as="element()*" tunnel="yes"/>
      <xsl:param name="orig-ref-so-far" as="xs:string?"/>
      <xsl:param name="new-ref-so-far" as="xs:string?"/>
      <xsl:variable name="this-type" select="tan:normalize-text(@type)"/>
      <xsl:variable name="this-n" select="@n"/>
      <xsl:variable name="div-types-to-suppress"
         select="$key-to-this-src[self::tan:suppress-div-types]/@div-type-ref"/>
      <xsl:variable name="div-ns-to-rename" select="$key-to-this-src[self::tan:rename-div-ns]"/>
      <xsl:variable name="these-renames"
         select="$div-ns-to-rename[@div-type-ref = $this-type]/tan:rename"/>
      <xsl:variable name="alias-specific" select="$these-renames[@old = $this-n]/@new"/>
      <xsl:choose>
         <xsl:when test="@type = $div-types-to-suppress">
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="orig-ref-so-far" select="$orig-ref-so-far"/>
               <xsl:with-param name="new-ref-so-far" select="$new-ref-so-far"/>
            </xsl:apply-templates>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="orig-ref"
               select="string-join(($orig-ref-so-far, (@orig-n, @n)[1]), $separator-hierarchy)"/>
            <xsl:variable name="new-ref"
               select="string-join(($new-ref-so-far, lower-case(($alias-specific, @n)[1])), $separator-hierarchy)"/>
            <!-- Homogenize tei:div to tan:div -->
            <div>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="ref" select="$new-ref"/>
               <xsl:if test="not($orig-ref = $new-ref)">
                  <xsl:attribute name="orig-ref" select="$orig-ref"/>
               </xsl:if>
               <xsl:if test="tan:help-requested(.) = true()">
                  <xsl:copy-of select="tan:help($orig-ref, ())"/>
               </xsl:if>
               <xsl:choose>
                  <xsl:when test="not(*:div)">
                     <!-- It's a leaf div, and we can normalize space, depending on whether it's TAN or TEI. Special TAN div-end punctuation (e.g., soft hyphen) is retained, for later use of tan:text-join() -->
                     <xsl:value-of select="normalize-space(.)"/>
                     <xsl:if test="exists(tei:*)">
                        <xsl:copy-of select="node()"/>
                     </xsl:if>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:apply-templates mode="#current">
                        <xsl:with-param name="orig-ref-so-far" select="$orig-ref"/>
                        <xsl:with-param name="new-ref-so-far" select="$new-ref"/>
                     </xsl:apply-templates>
                  </xsl:otherwise>
               </xsl:choose>
            </div>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>


   <xsl:function name="tan:arabic-numerals" as="xs:string*">
      <!-- Input: any strings that might be convertible to Arabic numerals, but of unknown format or type -->
      <!-- Output: Best-guess Arabic numeral equivalents, as strings. Roman numerals take precedence over alphabet numerals (that is, 'i' is interpreted as 1, not 9) -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:copy-of select="tan:strings-to-numeral-or-numeral-type($strings, true(), (), true())"/>
   </xsl:function>
   <xsl:function name="tan:arabic-numerals" as="xs:string*">
      <!-- Input: any strings that might be convertible to Arabic numerals, plus the type they are known to conform to -->
      <!-- Output: Best-guess Arabic numeral equivalents, as strings. -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:param name="treat-ambiguous-a-or-i-type-as-roman-numeral" as="xs:boolean?"/>
      <xsl:copy-of
         select="tan:strings-to-numeral-or-numeral-type($strings, true(), $treat-ambiguous-a-or-i-type-as-roman-numeral, true())"
      />
   </xsl:function>
   <xsl:function name="tan:number-type" as="xs:string*">
      <!-- Version of tan:strings-to-numeral-or-numeral-type() that fetches merely the numeral type -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:copy-of select="tan:strings-to-numeral-or-numeral-type($strings, false(), (), false())"/>
   </xsl:function>
   <xsl:function name="tan:strings-to-numeral-or-numeral-type" as="xs:string*">
      <!-- Input: any sequence of strings that may be a numeral type, and an indication whether what should be returned is not the type but the Arabic numeral equivalent (as a string) -->
      <!-- Output: the same number of strings, with the value of either the $n-type that is the first match or the Arabic numeral equivalent -->
      <!-- In general, Roman numerals are checked first, strings last ('i' = 1 not 9); mixed numeral types result in hyphen-joined Arabic numerals (e.g., 1a - > 1-1) -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:param name="convert-to-arabic" as="xs:boolean"/>
      <xsl:param name="treat-ambiguous-a-or-i-type-as-roman-numeral" as="xs:boolean?"/>
      <xsl:param name="preface-ambiguous-numeral-with-negative-sign" as="xs:boolean"/>
      <xsl:variable name="flag"
         select="
            if ($preface-ambiguous-numeral-with-negative-sign = true()) then
               -1
            else
               1"
         as="xs:integer"/>
      <xsl:variable name="these-types" as="xs:string*">
         <xsl:for-each select="$strings">
            <xsl:variable name="this-matches-rom" select="matches(., $n-type-pattern[1], 'i')"
               as="xs:boolean"/>
            <xsl:variable name="this-matches-aaa" select="matches(., $n-type-pattern[4], 'i')"
               as="xs:boolean"/>
            <xsl:choose>
               <xsl:when test="matches(., $n-type-pattern[2], 'i')">
                  <xsl:value-of select="$n-type[2]"/>
               </xsl:when>
               <xsl:when test="matches(., $n-type-pattern[3], 'i')">
                  <xsl:value-of select="$n-type[3]"/>
               </xsl:when>
               <xsl:when test="$this-matches-rom = true() and $this-matches-aaa = false()">
                  <xsl:value-of select="$n-type[1]"/>
               </xsl:when>
               <xsl:when test="$this-matches-rom = false() and $this-matches-aaa = true()">
                  <xsl:value-of select="$n-type[4]"/>
               </xsl:when>
               <xsl:when test="$this-matches-rom = true() and $this-matches-aaa = true()">
                  <xsl:value-of
                     select="
                        if ($convert-to-arabic = true() or not(exists($treat-ambiguous-a-or-i-type-as-roman-numeral))) then
                           $n-type[7]
                        else
                           if ($treat-ambiguous-a-or-i-type-as-roman-numeral = true()) then
                              $n-type[1]
                           else
                              $n-type[4]"
                  />
               </xsl:when>
               <xsl:when test="matches(., $n-type-pattern[5], 'i') and $convert-to-arabic = false()">
                  <xsl:value-of select="$n-type[5]"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$n-type[6]"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <!--<xsl:variable name="i-gt-a" as="xs:boolean"
         select="count($these-types[. = $n-type[1]]) gt count($these-types[. = $n-type[4]])"/>-->
      <!--<xsl:variable name="these-types-norm" as="xs:string*">
         <xsl:for-each select="$these-types">
            <xsl:choose>
               <xsl:when test=". = $n-type[7]">
                  <xsl:value-of
                     select="
                        if ($i-gt-a = true()) then
                           'i'
                        else
                           'a'"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>-->
      <xsl:choose>
         <xsl:when test="$convert-to-arabic = true()">
            <xsl:for-each select="1 to count($strings)">
               <xsl:variable name="pos" select="."/>
               <xsl:choose>
                  <xsl:when test="$these-types[$pos] = $n-type[1]">
                     <xsl:value-of select="tan:rom-to-int($strings[$pos])"/>
                  </xsl:when>
                  <xsl:when test="$these-types[$pos] = ($n-type[2], $n-type[6])">
                     <xsl:value-of select="$strings[$pos]"/>
                  </xsl:when>
                  <xsl:when test="$these-types[$pos] = $n-type[3]">
                     <xsl:value-of
                        select="concat(replace($strings[$pos], '\D+', ''), '-', tan:aaa-to-int(replace($strings[$pos], '\d+', '')))"
                     />
                  </xsl:when>
                  <xsl:when test="$these-types[$pos] = $n-type[4]">
                     <xsl:value-of select="tan:aaa-to-int($strings[$pos])"/>
                  </xsl:when>
                  <xsl:when test="$these-types[$pos] = $n-type[5]">
                     <xsl:value-of
                        select="concat(tan:aaa-to-int(replace($strings[$pos], '\d+', '')), '-', replace($strings[$pos], '\D+', ''))"
                     />
                  </xsl:when>
                  <xsl:when test="$these-types[$pos] = $n-type[7]">
                     <xsl:value-of
                        select="
                           if ($treat-ambiguous-a-or-i-type-as-roman-numeral = false()) then
                              tan:aaa-to-int($strings[$pos]) * $flag
                           else
                              tan:rom-to-int($strings[$pos]) * $flag"
                     />
                  </xsl:when>
               </xsl:choose>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$these-types"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tan:get-n-types" as="element()*">
      <!-- Input: any class 1 TAN documents -->
      <!-- Calculates types of @n values per div type per source and div type -->
      <!-- October 2016: this function used to be used for validation, but a better routine is preferred. The function is left here, however, in case it proves useful in other contexts. -->
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <xsl:for-each select="$src-1st-da-resolved">
         <xsl:variable name="this-doc" select="."/>
         <xsl:variable name="this-src-id" select="*/@src"/>
         <n-types src="{$this-src-id}">
            <xsl:for-each-group select="$this-doc//*:div" group-by="normalize-space(@type)">
               <xsl:variable name="this-div-type" select="current-grouping-key()"/>
               <xsl:variable name="div-type-decl"
                  select="$this-doc/*/tan:head/tan:declarations/tan:div-type[@xml:id = $this-div-type]"/>
               <xsl:variable name="this-ns-types"
                  select="
                     if (@ns-are-numerals = 'false') then
                        for $i in current-group()
                        return
                           '$'
                     else
                        tan:number-type(current-group()/@n)"/>
               <xsl:variable name="this-n-types-count"
                  select="
                     for $i in $n-type
                     return
                        count(index-of($this-ns-types, $i))"/>
               <xsl:variable name="this-dominant-n-type"
                  select="$n-type[index-of($this-n-types-count, max($this-n-types-count))[1]]"/>
               <div-type>
                  <xsl:copy-of select="$div-type-decl/@*"/>
                  <xsl:attribute name="type" select="current-grouping-key()"/>
                  <xsl:attribute name="n-type" select="$this-dominant-n-type"/>
                  <xsl:attribute name="ns-type-i" select="$this-n-types-count[1]"/>
                  <xsl:attribute name="ns-type-1" select="$this-n-types-count[2]"/>
                  <xsl:attribute name="ns-type-1a" select="$this-n-types-count[3]"/>
                  <xsl:attribute name="ns-type-a" select="$this-n-types-count[4]"/>
                  <xsl:attribute name="ns-type-a1" select="$this-n-types-count[5]"/>
                  <xsl:attribute name="ns-type-str" select="$this-n-types-count[6]"/>
                  <xsl:attribute name="ns-type-i-or-a" select="$this-n-types-count[7]"/>
                  <xsl:attribute name="unique-n-values" select="distinct-values(current-group()/@n)"
                  />
               </div-type>
            </xsl:for-each-group>
         </n-types>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:flatref" as="xs:string?">
      <!-- Simple, one-param function of the fuller one, below -->
      <xsl:param name="node" as="element()?"/>
      <xsl:value-of select="tan:flatref($node, (), ())"/>
   </xsl:function>
   <xsl:function name="tan:flatref" as="xs:string?">
      <!-- Input: div node in a TAN-T(EI) document; truth value whether references that fit a number pattern should be converted to integers -->
      <!-- Output: string value concatenating the reference values from the topmost div ancestor to the node. -->
      <!-- This function assumes that @n has already been normalized per tan:resolve-doc(), which converts @ns to Arabic numerals wherever possible -->
      <xsl:param name="node" as="element()?"/>
      <!--<xsl:param name="convert-to-arabic-numerals" as="xs:boolean"/>-->
      <!--<xsl:param name="ambiguous-numeral-types" as="element()*"/>-->
      <xsl:param name="div-types-to-suppress" as="xs:string*"/>
      <xsl:param name="div-ns-to-rename" as="element()*"/>
      <!--<xsl:value-of
         select="
            string-join($node/ancestor-or-self::*:div[not(@type = $div-types-to-suppress)]/@n, $separator-hierarchy)"
      />-->
      <xsl:variable name="flatref-items" as="xs:string*">
         <xsl:for-each select="$node/ancestor-or-self::*:div[not(@type = $div-types-to-suppress)]">
            <xsl:variable name="this-type" select="@type"/>
            <xsl:variable name="this-n" select="@n"/>
            <xsl:variable name="these-renames"
               select="$div-ns-to-rename[@div-type-ref = $this-type]/tan:rename"/>
            <xsl:variable name="alias-specific" select="$these-renames[@old = $this-n]/@new"/>
            <xsl:value-of select="lower-case(($alias-specific, $this-n)[1])"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($flatref-items, $separator-hierarchy)"/>
      <!--<xsl:choose>
         <xsl:when test="$convert-to-arabic-numerals = false()">
            <xsl:value-of
               select="
                  string-join(for $i in $node/ancestor-or-self::*:div
                  return
                     replace(normalize-space($i/@n), '\W+', $separator-hierarchy), $separator-hierarchy)"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="this-doc-amb-num-types"
               select="
                  if (exists($ambiguous-numeral-types)) then
                     $ambiguous-numeral-types
                  else
                     tan:analyze-attr-n-or-ref-numerals($node/ancestor::*:body/*:div, 'type', true(), false())"
            />
            <!-\-<xsl:variable name="flatref-analysis" as="element()*">
               <xsl:for-each select="$node/ancestor-or-self::*:div[not(@type = $div-types-to-suppress)]">
                  <xsl:apply-templates mode="arabic-numerals"></xsl:apply-templates>
               </xsl:for-each>
            </xsl:variable>-\->
            
            <xsl:value-of select="string-join($flatref-items, $separator-hierarchy)"/>
         </xsl:otherwise>
      </xsl:choose>-->
   </xsl:function>

   <!-- INFUSION -->
   <xsl:function name="tan:div-to-div-transfer" as="element()*">
      <!-- Input: (1) any set of divs with content to be transferred into the structure of (2) another  set of divs. -->
      <!-- Output: The div structure of (2), infused with the content of (1). The content is allocated  proportionately, with preference given to punctuation, within a certain range, and then word breaks. -->
      <!-- This function is useful for transforming class-1 documents from one reference system to another. It starts by getting the text content of (1), then string values for (2). -->
      <xsl:param name="divs-with-content-to-be-transferred" as="element()*"/>
      <xsl:param name="divs-to-be-infused-with-new-content" as="element()*"/>
      <xsl:variable name="content" select="tan:text-join($divs-with-content-to-be-transferred)"/>
      <xsl:variable name="attribute-names"
         select="
            for $i in $divs-to-be-infused-with-new-content//@*
            return
               name($i)"/>
      <xsl:variable name="mold-prep-1" as="element()">
         <mold>
            <xsl:apply-templates select="$divs-to-be-infused-with-new-content"
               mode="c1-stamp-string-length">
               <xsl:with-param name="mark-only-leaf-divs" select="false()" tunnel="yes"/>
            </xsl:apply-templates>
         </mold>
      </xsl:variable>
      <xsl:variable name="mold" as="element()">
         <xsl:apply-templates select="$mold-prep-1" mode="c1-stamp-string-pos">
            <xsl:with-param name="parent-pos" select="0"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="mold-infused" as="element()">
         <xsl:apply-templates select="$mold" mode="infuse-tokenized-text">
            <xsl:with-param name="raw-content-tokenized" select="tokenize($content, ' ')"
               tunnel="yes"/>
            <xsl:with-param name="total-length"
               select="sum(($mold//*:div)[last()]/(@string-length, @string-pos))" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <!--<test>
         <content><xsl:copy-of select="$content"/></content>
         <tokens count="{count(tokenize($content, ' '))}"><xsl:copy-of select="tokenize($content, ' ')"/></tokens>
         <total-length><xsl:copy-of select="sum(($mold//*:div)[last()]/(@string-length, @string-pos))"/></total-length>
      </test>-->
      <xsl:apply-templates select="$mold-infused/*" mode="strip-all-attributes-except">
         <xsl:with-param name="attributes-to-keep" select="$attribute-names" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>

   <xsl:template match="node()"
      mode="infuse-tokenized-text infuse-tokenized-div c1-stamp-string-length">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*:div[not(*:div)]" mode="infuse-tokenized-text">
      <xsl:param name="raw-content-tokenized" as="xs:string*" tunnel="yes"/>
      <xsl:param name="total-length" as="xs:double" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:variable name="this-first" as="xs:double?"
            select="ceiling(@string-pos div $total-length * count($raw-content-tokenized))"/>
         <xsl:variable name="next-first" as="xs:double?"
            select="ceiling((@string-pos + @string-length) div $total-length * count($raw-content-tokenized))"/>
         <xsl:variable name="text-sequence"
            select="subsequence($raw-content-tokenized, $this-first, ($next-first - $this-first))"/>
         <xsl:copy-of select="string-join($text-sequence, ' ')"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div" mode="infuse-tokenized-div">
      <xsl:param name="div-clay-tokenized" as="element()*" tunnel="yes"/>
      <xsl:param name="infuse-deeply" as="xs:boolean?" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="($div-clay-tokenized//@src)[1]"/>
         <xsl:copy-of select="@* except @src"/>
         <xsl:choose>
            <xsl:when test="exists(tan:div) and $infuse-deeply = true()">
               <xsl:apply-templates mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="leaf-div-pos"
                  select="
                     count(if ($infuse-deeply = true()) then
                        preceding::tan:div[not(tan:div)]
                     else
                        preceding-sibling::tan:div) + 1"/>
               <xsl:variable name="that-clay" select="$div-clay-tokenized[$leaf-div-pos]"/>
               <xsl:for-each select="$that-clay//tan:div[tan:ver]">
                  <ver>
                     <xsl:copy-of select="@*"/>
                     <xsl:value-of select="normalize-space(.)"/>
                  </ver>
               </xsl:for-each>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>

   <!-- STRING LENGTHS, POS -->

   <xsl:function name="tan:analyze-string-length" as="item()*">
      <!-- One-parameter function of the two-parameter version below -->
      <xsl:param name="resolved-class-1-doc-or-fragment" as="item()*"/>
      <xsl:copy-of select="tan:analyze-string-length($resolved-class-1-doc-or-fragment, false())"/>
   </xsl:function>

   <xsl:function name="tan:analyze-string-length" as="item()*">
      <!-- Input: any class-1 document or fragment; an indication whether string lengths should be added only to leaf divs, or to every div. -->
      <!-- Output: the same document, with @string-length and @string-pos added to every div -->
      <!-- Function to calculate string lengths of each leaf elements and their relative position, so that a raw text can be segmented proportionally and given the structure of a model exemplar. NB: any $special-end-div-chars that terminate a <div> not only will not be counted, but the
         assumed space that follows will also not be counted. On the other hand, the lack of a special
         character at the end means that the nominal space that follows a div will be included in both
         the length and the position. Thus input...
         <div type="m" n="1">abc&#xad;</div>
         <div type="m" n="2">def&#x200d;</div>
         <div type="m" n="3">ghi</div>
         <div type="m" n="4">xyz</div>
         ...presumes a raw joined text of "abcdefghi xyz ", and so becomes output:
         <div type="m" n="1" string-length="3" string-pos="1">abc&#xad;</div>
         <div type="m" n="2" string-length="3" string-pos="4">def&#x200d;</div>
         <div type="m" n="3" string-length="4" string-pos="7">ghi</div>
         <div type="m" n="4" string-length="4" string-pos="11">xyz</div> -->
      <xsl:param name="resolved-class-1-doc-or-fragment" as="item()*"/>
      <xsl:param name="mark-only-leaf-divs" as="xs:boolean"/>
      <xsl:variable name="pass-1">
         <xsl:apply-templates select="$resolved-class-1-doc-or-fragment"
            mode="c1-stamp-string-length">
            <xsl:with-param name="mark-only-leaf-elements" select="$mark-only-leaf-divs"
               tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <!--<xsl:copy-of select="$pass-1/*"/>-->
      <xsl:apply-templates select="$pass-1" mode="c1-stamp-string-pos">
         <xsl:with-param name="parent-pos" select="0"/>
         <xsl:with-param name="mark-only-leaf-elements" select="$mark-only-leaf-divs" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="*:body | *:div | tan:tok | tan:non-tok" mode="c1-stamp-string-length">
      <xsl:param name="mark-only-leaf-elements" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="is-leaf" select="not(exists(*))" as="xs:boolean"/>
      <xsl:variable name="is-tok" select="exists(self::tan:tok) or exists(self::tan:non-tok)"
         as="xs:boolean"/>
      <!--<xsl:variable name="text-is-tokenized" select="exists(descendant-or-self::tan:tok)" as="xs:boolean"/>-->
      <xsl:choose>
         <xsl:when test="$mark-only-leaf-elements = true() and $is-leaf = false()">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <!-- The string length will include the hypothetical space that follows the div (or if an special end-div marker is present, the space  and the marker will be ignored -->
               <xsl:attribute name="string-length"
                  select="
                     tan:string-length(if ($is-tok = true()) then
                        .
                     else
                        tan:text-join(.))"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- The following extensions of c1-stamp-string-length to process tan:diff() results -->
   <xsl:template match="tan:s1 | tan:s2 | tan:common" mode="c1-stamp-string-length">
      <xsl:variable name="this-length" select="string-length(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="self::tan:common or self::tan:s1">
            <xsl:attribute name="s1-length" select="$this-length"/>
         </xsl:if>
         <xsl:if test="self::tan:common or self::tan:s2">
            <xsl:attribute name="s2-length" select="$this-length"/>
         </xsl:if>
         <xsl:copy-of select="text()"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*" mode="c1-stamp-string-pos">
      <xsl:param name="parent-pos" as="xs:integer"/>
      <xsl:param name="mark-only-leaf-elements" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="preceding-string-lengths"
         select="
            if ($mark-only-leaf-elements = true()) then
               preceding-sibling::*//descendant-or-self::*[not(*)]/@string-length
            else
               preceding-sibling::*/@string-length"
      />
      <xsl:variable name="preceding-sibling-pos" as="xs:integer">
         <xsl:choose>
            <xsl:when test="exists($preceding-string-lengths)">
               <xsl:copy-of select="xs:integer(sum($preceding-string-lengths))"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="0"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="this-string-pos" select="$parent-pos + $preceding-sibling-pos"
         as="xs:integer?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(@string-length)">
            <xsl:attribute name="string-pos" select="$this-string-pos + 1"/>
         </xsl:if>
         <!-- next items for tan:s1 | tan:s2 | tan:common, from the diff function -->
         <xsl:if test="exists(@s1-length)">
            <xsl:attribute name="s1-pos" select="sum(preceding-sibling::*/@s1-length) + 1"/>
         </xsl:if>
         <xsl:if test="exists(@s2-length)">
            <xsl:attribute name="s2-pos" select="sum(preceding-sibling::*/@s2-length) + 1"/>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="parent-pos" select="$this-string-pos"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <!-- STATS -->

   <xsl:function name="tan:analyze-stats" as="element()?">
      <!-- Takes a series of integers, doubles, or other numbers and returns basic statistics
      as attributes in a single element -->
      <xsl:param name="arg" as="xs:anyAtomicType*"/>
      <xsl:variable name="this-avg" select="avg($arg)"/>
      <xsl:variable name="these-deviations"
         select="
            for $i in $arg
            return
               math:pow(($i - $this-avg), 2)"/>
      <xsl:variable name="this-variance" select="avg($these-deviations)"/>
      <xsl:variable name="this-standard-deviation" select="math:sqrt($this-variance)"/>
      <stats xmlns="tag:textalign.net,2015:ns">
         <xsl:attribute name="count" select="count($arg)"/>
         <xsl:attribute name="sum" select="sum($arg)"/>
         <xsl:attribute name="avg" select="$this-avg"/>
         <xsl:attribute name="max" select="max($arg)"/>
         <xsl:attribute name="min" select="min($arg)"/>
         <xsl:attribute name="var" select="$this-variance"/>
         <xsl:attribute name="std" select="$this-standard-deviation"/>
         <xsl:for-each select="$arg">
            <xsl:variable name="pos" select="position()"/>
            <xsl:element name="d" namespace="tag:textalign.net,2015:ns">
               <xsl:attribute name="dev" select="$these-deviations[$pos]"/>
               <xsl:value-of select="."/>
            </xsl:element>
         </xsl:for-each>
      </stats>
   </xsl:function>

   <xsl:function name="tan:number-sort" as="xs:double*">
      <!-- Input: any sequence of items -->
      <!-- Output: the same sequence, sorted with string numerals converted to numbers -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="numbers-norm" as="item()*"
         select="
            for $i in $numbers
            return
               if ($i instance of xs:string) then
                  number($i)
               else
                  $i"/>
      <xsl:for-each select="$numbers-norm">
         <xsl:sort/>
         <xsl:copy-of select="."/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:median" as="xs:double?">
      <!-- Input: any sequence of numbers -->
      <!-- Output: the median value -->
      <!-- It is assumed that the input has already been sorted by tan:numbers-sorted() vel sim -->
      <xsl:param name="numbers" as="xs:double*"/>
      <xsl:variable name="number-count" select="count($numbers)"/>
      <xsl:variable name="mid-point" select="$number-count div 2"/>
      <xsl:variable name="mid-point-ceiling" select="ceiling($mid-point)"/>
      <xsl:choose>
         <xsl:when test="$mid-point = $mid-point-ceiling">
            <xsl:copy-of
               select="avg(($numbers[$mid-point-ceiling], $numbers[$mid-point-ceiling - 1]))"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="xs:double($numbers[$mid-point-ceiling])"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tan:outliers" as="xs:anyAtomicType*">
      <!-- Input: any sequence of numbers -->
      <!-- Output: outliers in the sequence, -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="numbers-sorted" select="tan:number-sort($numbers)" as="xs:anyAtomicType*"/>
      <xsl:variable name="half-point" select="count($numbers) idiv 2"/>
      <xsl:variable name="top-half" select="$numbers-sorted[position() le $half-point]"/>
      <xsl:variable name="bottom-half" select="$numbers-sorted[position() gt $half-point]"/>
      <xsl:variable name="q1" select="tan:median($top-half)"/>
      <xsl:variable name="q2" select="tan:median($numbers)"/>
      <xsl:variable name="q3" select="tan:median($bottom-half)"/>
      <xsl:variable name="interquartile-range" select="$q3 - $q1"/>
      <xsl:variable name="outer-fences" select="$interquartile-range * 3"/>
      <xsl:variable name="top-fence" select="$q1 - $outer-fences"/>
      <xsl:variable name="bottom-fence" select="$q3 + $outer-fences"/>
      <xsl:variable name="top-outliers" select="$top-half[. lt $top-fence]"/>
      <xsl:variable name="bottom-outliers" select="$bottom-half[. gt $bottom-fence]"/>
      <xsl:for-each select="$numbers">
         <xsl:variable name="this-number"
            select="
               if (. instance of xs:string) then
                  number(.)
               else
                  xs:double(.)"/>
         <xsl:if test="$this-number = ($top-outliers, $bottom-outliers)">
            <xsl:copy-of select="."/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:no-outliers" as="xs:anyAtomicType*">
      <!-- Input: any sequence of numbers -->
      <!-- Output: the same sequence, without outliers -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="outliers" select="tan:outliers($numbers)"/>
      <xsl:copy-of select="$numbers[not(. = $outliers)]"/>
   </xsl:function>


   <!-- MERGED SOURCES AND SKELETONS -->
   <xsl:function name="tan:get-src-skeleton" as="document-node()?">
      <!-- one-parameter form of the master version below; it results in a merger of sources, but without text and empty leaf divs -->
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:copy-of select="tan:merge-sources($src-1st-da-prepped, false(), false(), ())"/>
   </xsl:function>
   <xsl:function name="tan:merge-sources" as="document-node()?">
      <!-- two-parameter form of the master function below; it results in a merger of sources, but keeping text, juxtaposed in leaf divs and differentiated with new <ver src="[SOURCE NAME]"> to  distinguish one version from the next -->
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:param name="keep-sources-in-order" as="xs:boolean?"/>
      <xsl:copy-of
         select="tan:merge-sources($src-1st-da-prepped, true(), $keep-sources-in-order, ())"/>
   </xsl:function>
   <xsl:function name="tan:merge-sources" as="document-node()?">
      <!-- input: one or more prepped class 1 document (usually has @ref with flatref values); a boolean indicating whether text should be kept or dropped (skeleton);  and a boolean indicating whether the order of sources should be respected -->
      <!-- output: a single document that merges the bodies of the input documents into a single structure based on the values of @ref -->
      <!-- This function is useful for determining orphan, defective, and complete <div>s, and in preparation of publishing TAN-A-div files. To that end, this function automatically handles <div>s that have been marked for realignment. -->
      <!-- This function assumes that the sources have at the bare minimum gone through the first level of preparation; that is, tei:TEI, tei:body, and tei:div have been converted to TAN equivalents, and the only tei elements in the body are in leaf divs. -->
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <!-- Nov 2016: demoting keep-what-attributes feature. Use tan:copy-of-except() instead, after processing -->
      <!--<xsl:param name="keep-what-attributes" as="xs:string*"/>-->
      <xsl:param name="keep-text" as="xs:boolean"/>
      <xsl:param name="keep-sources-in-order" as="xs:boolean?"/>
      <xsl:param name="add-stats" as="xs:boolean?"/>
      <xsl:variable name="sources-prepped-for-merge" as="document-node()*">
         <!-- stripping down the sources entails getting rid of processing instructions, adding @src to the root element and every <div>, stripping away the text (if so requested) -->
         <xsl:for-each select="$src-1st-da-prepped">
            <!--<xsl:variable name="root-src" select="root(.)/*/@src"/>-->
            <!--<xsl:variable name="src"
               select="
                  if (exists($root-src)) then
                     $root-src
                  else
                     position()"/>-->
            <xsl:document>
               <xsl:apply-templates select="." mode="prepare-class-1-doc-for-merge">
                  <!--<xsl:with-param name="src" select="$src" tunnel="yes"/>-->
                  <!--<xsl:with-param name="keep-what-attributes" select="$keep-what-attributes"
                     tunnel="yes"/>-->
                  <xsl:with-param name="keep-text" select="$keep-text" as="xs:boolean" tunnel="yes"
                  />
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="body-stats-merged"
         select="tan:merge-analyzed-stats($sources-prepped-for-merge/*/tan:body, $add-stats)"/>
      <xsl:variable name="all-src-ids" select="$sources-prepped-for-merge/*/@src" as="xs:string*"/>
      <xsl:variable name="sources-raw-merge" as="document-node()?">
         <xsl:document>
            <TAN-T>
               <xsl:attribute name="src" select="string-join($all-src-ids, ' ')"/>
               <xsl:attribute name="id" namespace="http://www.w3.org/XML/1998/namespace"
                  select="
                     concat(string-join($sources-prepped-for-merge/*/@xml:id, '--'), (if ($add-stats = true()) then
                        ('---add')
                     else
                        ('---diff')))"/>
               <xsl:copy-of select="$sources-prepped-for-merge/*/tan:head"/>
               <!--<test><xsl:copy-of select="$body-stats-merged"/></test>-->
               <body>
                  <xsl:copy-of select="$body-stats-merged/(@*, node())"/>
                  <xsl:copy-of select="$sources-prepped-for-merge/*/tan:body/tan:div"/>
               </body>
               <tail>
                  <xsl:copy-of select="$sources-prepped-for-merge/*/tan:tail/tan:div"/>
               </tail>
            </TAN-T>
         </xsl:document>
      </xsl:variable>
      <!--<xsl:copy-of select="$sources-prepped-for-merge[3]"/>-->
      <!--<xsl:copy-of select="$sources-raw-merge"/>-->
      <xsl:copy-of
         select="
            tan:merge-source-loop($sources-raw-merge, 1, $add-stats, (if ($keep-sources-in-order = true()) then
               $all-src-ids
            else
               ()))"
      />
   </xsl:function>

   <xsl:template match="processing-instruction()" mode="prepare-class-1-doc-for-merge"/>
   <xsl:template match="*" mode="prepare-class-1-doc-for-merge">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-T" mode="prepare-class-1-doc-for-merge">
      <xsl:variable name="this-doc-id"
         select="
            if (exists(@src)) then
               @src
            else
               @id"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="src" select="$this-doc-id" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body" mode="prepare-class-1-doc-for-merge">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="sibling-div-count" select="count(tan:div)"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:template match="tan:div" mode="prepare-class-1-doc-for-merge">
      <!-- This template is long, because it deals with cases where individual <div>s have been realigned by a TAN-A-div file. <div>s that must be realigned are best done so in this method, since one cannot predict where in a hierarchy an anchor and anchoree are to be found -->
      <xsl:param name="src" tunnel="yes"/>
      <xsl:param name="tan-a-div-prepped" as="document-node()?" tunnel="yes"/>
      <xsl:param name="inherited-ref" as="xs:string?"/>
      <xsl:param name="sibling-div-count" as="xs:integer?"/>
      <xsl:param name="is-being-reanchored" as="xs:boolean?"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="this-n" select="@n"/>
      <xsl:variable name="likely-new-ref" select="concat($inherited-ref, ' ', @n)"/>
      <xsl:variable name="this-pos" select="count(preceding-sibling::tan:div) + 1"/>
      <xsl:variable name="first-realign" select="($tan-a-div-prepped/tan:TAN-A-div/tan:body/tan:realign[tan:div-ref[@src = $src][tan:div/@ref = $this-ref]])[1]"/>
      <xsl:variable name="where-this-div-is-realigned" select="$first-realign/tan:div-ref[@src = $src][tan:div/@ref = $this-ref]"/>
      <xsl:variable name="other-div-to-which-this-div-should-be-moved"
         select="$where-this-div-is-realigned[1]/(preceding-sibling::tan:anchor-div-ref, preceding-sibling::tan:div-ref)[1]"
      />
      <xsl:variable name="where-this-div-is-an-anchor" select="$tan-a-div-prepped/tan:TAN-A-div/tan:body/tan:realign/tan:anchor-div-ref[@src = $src][tan:div/@ref = $this-ref]"/>
      <xsl:variable name="other-div-refs-that-should-be-moved-here"
         select="
            if (exists($where-this-div-is-an-anchor)) then
               $where-this-div-is-an-anchor/following-sibling::tan:div-ref
            else
               if (not(exists($other-div-to-which-this-div-should-be-moved))) then
                  $where-this-div-is-realigned[1]/following-sibling::tan:div-ref
               else
                  ()"
      />
      <xsl:variable name="realigns-that-dislodge-this-div"
         select="$tan-a-div-prepped/tan:TAN-A-div/tan:body/tan:realign[tan:anchor-div-ref[tan:div/@ref = $likely-new-ref and not(@src = $src)] and tan:div-ref[@src = $src]]"
      />
      <xsl:choose>
         <!-- If this <div> is to be moved, skip it -->
         <xsl:when
            test="exists($other-div-to-which-this-div-should-be-moved) and not(exists($where-this-div-is-an-anchor)) and not($is-being-reanchored = true())"
         />
         <xsl:otherwise>
            <!-- The <div> is not involved in a realign or it is but only as the anchor or as the first <div> of an unanchored realign, should it be copied, perhaps with trailing <div>s that are to be reanchored -->
            <xsl:variable name="this-revised-ref" as="xs:string?">
               <xsl:choose>
                  <xsl:when test="not(exists($where-this-div-is-an-anchor)) and exists($where-this-div-is-realigned) and not(exists($other-div-to-which-this-div-should-be-moved))">
                     <!-- If the <div> is the first in an unanchored realign, just adopt the @id of the realignment -->
                     <xsl:value-of select="$first-realign/@id"/>
                  </xsl:when>
                  <xsl:when test="$is-being-reanchored = true()">
                     <xsl:value-of select="$inherited-ref"/>
                  </xsl:when>
                  <xsl:when test="exists($realigns-that-dislodge-this-div)">
                     <xsl:value-of select="concat('#', $likely-new-ref)"/>
                  </xsl:when>
                  <xsl:when test="string-length($inherited-ref) gt 1">
                     <xsl:value-of select="$likely-new-ref"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:value-of select="@ref"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:copy>
               <xsl:copy-of select="@*  except @ref"/>
               <xsl:attribute name="ref" select="$this-revised-ref"/>
               <xsl:if test="not($this-revised-ref = @ref)">
                  <xsl:attribute name="pre-realign-ref" select="@ref"/>
               </xsl:if>
               <xsl:attribute name="src" select="$src"/>
               <xsl:attribute name="r" select="$this-pos div $sibling-div-count"/>
               <xsl:choose>
                  <xsl:when test="@type = '#seg'">
                     <!-- If this is a segment, the children should be wrappen in <ver> -->
                     <ver src="{$src}">
                        <xsl:if test="$is-being-reanchored = true()">
                           <xsl:attribute name="pre-realign-ref" select="@ref"/>
                        </xsl:if>
                        <xsl:copy-of select="*"/>
                     </ver>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:apply-templates mode="#current">
                        <xsl:with-param name="inherited-ref" select="$this-revised-ref"/>
                        <xsl:with-param name="sibling-div-count" select="count(tan:div)"/>
                     </xsl:apply-templates>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:copy>
            <xsl:for-each select="$other-div-refs-that-should-be-moved-here">
               <xsl:apply-templates mode="#current" select="tan:div">
                  <xsl:with-param name="inherited-ref" select="$this-revised-ref"/>
                  <xsl:with-param name="src" select="@src" tunnel="yes"/>
                  <xsl:with-param name="is-being-reanchored" select="true()"/>
                  <xsl:with-param name="sibling-div-count" select="count(tan:div)"/>
               </xsl:apply-templates>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="text()[matches(., '\S')] | tei:*[not(preceding-sibling::tei:*)]" mode="prepare-class-1-doc-for-merge">
      <xsl:param name="src" tunnel="yes"/>
      <xsl:param name="keep-text" tunnel="yes" as="xs:boolean"/>
      <xsl:if test="$keep-text = true()">
         <ver src="{$src}">
            <xsl:copy-of select="../@orig-ref"/>
            <xsl:copy-of select="."/>
            <xsl:copy-of select="following-sibling::tei:*"/>
         </ver>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tei:*[preceding-sibling::tei:*]" mode="prepare-class-1-doc-for-merge"/>
   
   <xsl:function name="tan:merge-analyzed-stats" as="element()">
      <!-- Takes a group of elements that follow the pattern that results from tan:analyze-stats and synthesizes them into a single element. If $add-stats is true, then they are added; if false, the sum of the 2nd - last elements is subtracted from the first; if neither true nor false, nothing happens. Will work on elements of any name, so long as they have tan:d children, with the data points to be merged. -->
      <xsl:param name="analyzed-stats" as="element()*"/>
      <xsl:param name="add-stats" as="xs:boolean?"/>
      <xsl:variable name="datum-counts" as="xs:integer*"
         select="
            for $i in $analyzed-stats
            return
               count($i/tan:d)"/>
      <xsl:variable name="data-summed" as="xs:anyAtomicType*"
         select="
            for $i in (1 to $datum-counts[1])
            return
               sum($analyzed-stats/tan:d[$i])"/>
      <xsl:variable name="data-diff" as="element()">
         <stats>
            <xsl:attribute name="count"
               select="(avg($analyzed-stats[position() gt 1]/@count)) - $analyzed-stats[1]/@count"/>
            <xsl:attribute name="sum"
               select="(avg($analyzed-stats[position() gt 1]/@sum)) - $analyzed-stats[1]/@sum"/>
            <xsl:attribute name="avg"
               select="(avg($analyzed-stats[position() gt 1]/@avg)) - $analyzed-stats[1]/@avg"/>
            <xsl:attribute name="max"
               select="(avg($analyzed-stats[position() gt 1]/@max)) - $analyzed-stats[1]/@max"/>
            <xsl:attribute name="min"
               select="(avg($analyzed-stats[position() gt 1]/@min)) - $analyzed-stats[1]/@min"/>
            <xsl:attribute name="var"
               select="(avg($analyzed-stats[position() gt 1]/@var)) - $analyzed-stats[1]/@var"/>
            <xsl:attribute name="std"
               select="(avg($analyzed-stats[position() gt 1]/@std)) - $analyzed-stats[1]/@std"/>
            <xsl:for-each select="$analyzed-stats[1]/tan:d">
               <xsl:variable name="pos" select="position()"/>
               <d>
                  <xsl:copy-of
                     select="avg($analyzed-stats[position() gt 1]/tan:d[$pos]) - $analyzed-stats[1]/tan:d[$pos]"
                  />
               </d>
            </xsl:for-each>
         </stats>
      </xsl:variable>
      <stats>
         <xsl:choose>
            <xsl:when test="$analyzed-stats/tan:d and count(distinct-values($datum-counts)) gt 1">
               <xsl:copy-of select="tan:error('adv03', $datum-counts)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:choose>
                  <xsl:when test="$add-stats = true() and $analyzed-stats/tan:d">
                     <xsl:copy-of select="tan:analyze-stats($data-summed)/(@*, node())"/>
                  </xsl:when>
                  <xsl:when test="$add-stats = false() and $analyzed-stats/tan:d">
                     <xsl:copy-of select="$data-diff/(@*, node())"/>
                     <!--<xsl:copy-of select="tan:analyze-stats($data-diff)/(@*, node())"/>-->
                  </xsl:when>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </stats>
   </xsl:function>

   <xsl:function name="tan:merge-source-loop" as="document-node()?">
      <!-- Input: a rough merge (the result of tan:merge-source()); an initial depth (usually 1), a boolean indicating whether statistics, if present, should be added or if the sum of tail should be subtracted from the head, and a list of source ids (only if the order of sources should be respected) -->
      <!-- Output: a single document that joins sibling <div>s that share a common @ref. Further, if any statistics are present and $add-stats is true, then the matching  attributes in merged <d>s are added or checked for differences, as required. If $add-stats is false then the statistics are subtracted (the head of the sequence minus the sum of the tail of the sequence) -->
      <!-- No special provision is made for the order of synthesized <div>s; to control for order, the input unmerged sources in every <div> should have an @r that specifies the relative rank (values 0 to 1) a div takes. The average of the @r's will be calculated in the merged <div>, so that sorting can take place. In some cases, that @r-avg can be misleading, since it excludes any outliers of @r (to avoid the undue influence of <div>s inserted via realignment or of sources that have the work in only a fragmentary state), but the data needed to recalculate the proper average and re-sort the <div>s should all be present. -->
      <!-- If, in the course of preparation, all the children <div>s of a <div> have been eliminated, because of <realign>s in a TAN-A-div file, the result is a hollow <div>, with neither <ver> nor <div> children. These are retained in the loop; if they are to be omitted, it should be done by whatever process handles these results. -->
      <xsl:param name="not-fully-merged-source" as="document-node()?"/>
      <!--<xsl:param name="keep-what-attributes" as="xs:string*"/>-->
      <xsl:param name="so-far-merged-to-what-depth" as="xs:integer"/>
      <xsl:param name="add-stats" as="xs:boolean?"/>
      <xsl:param name="order-of-source-ids" as="xs:string*"/>
      <xsl:variable name="max-depth" as="xs:integer"
         select="
            max(((for $i in $not-fully-merged-source/tan:*/(tan:body, tan:work)//tan:div[not(tan:div)]
            return
               count($i/ancestor-or-self::tan:div)), 0))"/>
      <xsl:choose>
         <xsl:when test="$so-far-merged-to-what-depth gt $max-depth">
            <xsl:copy-of select="$not-fully-merged-source"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="next-level-of-merge">
               <xsl:document>
                  <xsl:apply-templates select="$not-fully-merged-source"
                     mode="synthesize-merged-sources">
                     <xsl:with-param name="depth" select="$so-far-merged-to-what-depth" tunnel="yes"/>
                     <xsl:with-param name="add-stats" select="$add-stats" tunnel="yes"/>
                     <xsl:with-param name="order-of-source-ids" tunnel="yes"
                        select="$order-of-source-ids"/>
                  </xsl:apply-templates>
               </xsl:document>
            </xsl:variable>
            <!--<xsl:copy-of select="$next-level-of-merge"/>-->
            <xsl:copy-of
               select="tan:merge-source-loop($next-level-of-merge, $so-far-merged-to-what-depth + 1, $add-stats, $order-of-source-ids)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:template match="node()" mode="synthesize-merged-sources">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:ver" mode="synthesize-merged-sources">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template
      match="tan:work//tan:div | tan:TAN-T/tan:body//tan:div | tan:body[tan:div] | tan:work[tan:div]"
      mode="synthesize-merged-sources">
      <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
      <xsl:param name="add-stats" as="xs:boolean?" tunnel="yes"/>
      <xsl:param name="keep-what-attributes" tunnel="yes"/>
      <xsl:param name="order-of-source-ids" tunnel="yes" as="xs:string*"/>
      <xsl:variable name="this-depth" select="count(ancestor::*)"/>
      <!--<xsl:variable name="this-tail" select="(root()/tan:TAN-T/tan:tail, ancestor-or-self::tan:work/tan:realigned)"/>-->
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="self::tan:body or self::tan:work">
            <xsl:attribute name="add-stats" select="$add-stats"/>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="$this-depth lt $depth">
               <xsl:apply-templates mode="synthesize-merged-sources"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="tan:d"/>
               <xsl:choose>
                  <xsl:when test="count($order-of-source-ids) gt 0">
                     <!-- This option is used to force sources to stay in order. Thus, given a merge of sources A, B, C, and D, if B terminates in a leaf div but the others do not, then  there will be three groups formed: A, B, and C+D. This is useful for preparing for comparisons where the sources must stay in a consistent order. -->
                     <xsl:for-each-group select="* except tan:d" group-adjacent="name()">
                        <!-- Ensure, first of all, that the position of any <ver> (which signals a leaf div) is respected, by first grouping according to the names of elements -->
                        <xsl:choose>
                           <xsl:when test="current-grouping-key() = 'div'">
                              <xsl:for-each-group select="current-group()" group-by="@ref">
                                 <!--<xsl:sort select="avg(tan:no-outliers(current-group()/@r))"/>-->

                                 <xsl:variable name="this-group-reordered" as="element()*">
                                    <xsl:for-each select="current-group()">
                                       <xsl:sort select="index-of($order-of-source-ids, @src)"/>
                                       <xsl:copy-of select="."/>
                                    </xsl:for-each>
                                 </xsl:variable>
                                 <xsl:copy-of
                                    select="tan:synthesize-merged-group($this-group-reordered, $add-stats)"
                                 />
                              </xsl:for-each-group>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy-of select="current-group()"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:for-each-group>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- This option ignores source order, and consolidates wherever possible. So given a merge of sources A, B, C, and D, if B is a leaf div but the others are not, then  B will appear, then the grouping of A+C+D. This approach is useful where it is important to ensure that groups of divs with the same ref are consolidated in the same group. -->
                     <xsl:copy-of select="* except (tan:d, tan:div)"/>
                     <xsl:for-each-group select="tan:div" group-by="@ref">
                        <!--<xsl:sort select="avg(tan:no-outliers(current-group()/@r))"/>-->

                        <xsl:copy-of
                           select="tan:synthesize-merged-group(current-group(), $add-stats)"/>
                     </xsl:for-each-group>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:synthesize-merged-group" as="element()?">
      <!-- Input: a group of elements that share the same @ref; a parameter indicating whether stats, if present, should be added -->
      <!-- Output: a single element that merges the content of the grouped element -->
      <!-- This function is intended solely for the template synthesize-src-skeleton, to handle in identical ways content that has been chosen and ordered differently. -->
      <xsl:param name="current-group" as="element()*"/>

      <xsl:param name="add-stats" as="xs:boolean?"/>
      <xsl:variable name="these-data-merged"
         select="tan:merge-analyzed-stats($current-group, $add-stats)"/>
      <xsl:element name="{name($current-group[1])}">
         <xsl:copy-of select="($current-group/@ref)[1]"/>
         <!--<xsl:for-each-group select="$current-group/(@* except @ref)" group-by="name()">
            <xsl:attribute name="{current-grouping-key()}" select="distinct-values(current-group())"
            />
         </xsl:for-each-group>-->
         <xsl:attribute name="src" select="distinct-values($current-group/@src)"/>
         <xsl:if test="exists($current-group/@r)">
            <xsl:attribute name="r-avg" select="avg(tan:no-outliers($current-group/@r))"/>
         </xsl:if>
         <xsl:copy-of select="$these-data-merged/(@*, node())"/>
         <xsl:for-each select="$current-group">
            <attr>
               <xsl:copy-of select="@* except @ref"/>
            </attr>
         </xsl:for-each>
         <xsl:for-each select="$current-group">
            <xsl:variable name="this-count" select="count(*)"/>
            <xsl:for-each select="*">
               <xsl:sort select="@r"/>
               <xsl:variable name="pos" select="position()"/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="node()"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:element>
   </xsl:function>
</xsl:stylesheet>
