<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-LM files.</title>
   <!-- to do: 
      Check @only-if-has-features to make sure it matches either a @code or feature/@xml:id 
      invalid patterns plus warning from TAN-R-mor file
      l may be left empty, indicating that the value of the word tokens must be used. In this case, all values of tok must resolve to the same value, or a validation error will result.
      If a ? is in <m> return a help-requested message, much like @ref
      any <m> that has too many codes will return not only an error but the meanings of the valid codes currently placed. For example, <m>rb ?</m> using a TAN-R-mor file with only one <category> might return this error: Too many codes, which currently resolve: adverb.
   -->
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>

   <include href="TAN-core.sch"/>
   <pattern id="self-prepped" is-a="tan-file-resolved">
      <param name="self-version" value="$self-prepped"/>
   </pattern>
   
   <!--<include href="TAN-class-2.sch"/>
   <include href="TAN-class-2-edit.sch"/>
   <include href="TAN-class-2-quarter.sch"/>
   <include href="TAN-class-2-half.sch"/>
   <include href="TAN-class-2-full.sch"/>-->
   <!--<phase id="edit-no-SQFs">
      <active pattern="LM-edit-no-SQFs"/>
   </phase>-->
   <!--<phase id="edit-test">
      <active pattern="LM-edit-test"/>
   </phase>-->
   <!--<phase id="edit-missing-ls">
      <!-\-<active pattern="class-2-edit"/>-\->
      <active pattern="LM-edit-missing-ls"/>
   </phase>-->
   <!--<phase id="edit-grouped-data">
      <active pattern="LM-core"/>
      <active pattern="class-2-edit"/>
      <active pattern="LM-edit-grouped-data"/>
   </phase>
   <phase id="quarter">
      <active pattern="core"/>
      <active pattern="class-2"/>
      <!-\-<active pattern="LM-core"/>-\->
      <active pattern="class-2-quarter"/>
      <!-\-<active pattern="LM-quarter"/>-\->
   </phase>
   <phase id="half">
      <active pattern="core"/>
      <active pattern="class-2"/>
      <active pattern="LM-core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="LM-quarter"/>
      <active pattern="LM-half"/>
   </phase>
   <phase id="full">
      <active pattern="core"/>
      <active pattern="class-2"/>
      <active pattern="LM-core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="class-2-full"/>
      <active pattern="LM-quarter"/>
      <active pattern="LM-half"/>
      <active pattern="LM-full"/>
   </phase>-->

   <sqf:fixes>
      <sqf:fix id="delete-chosen-l-or-m">
         <sqf:param name="l-or-m-element" type="element()"/>
         <sqf:description>
            <sqf:title>Delete a specific l or m (or entire lm if only one l exists)</sqf:title>
         </sqf:description>
         <let name="focus"
            value="
               if ($l-or-m-element/(following-sibling::tan:l, preceding-sibling::tan:l)) then
                  $l-or-m-element
               else
                  $l-or-m-element/.."/>
         <sqf:delete match="$focus, $focus/following-sibling::node()[1][self::text()]"/>
      </sqf:fix>
      <sqf:fix id="delete-chosen-l-or-m-globally">
         <sqf:param name="l-or-m-element" type="element()"/>
         <sqf:description>
            <sqf:title>Delete instances of a l or m globally</sqf:title>
         </sqf:description>
         <let name="focus" value="tan:get-matching-ls-or-ms($l-or-m-element)"/>
         <sqf:delete match="$focus, $focus/following-sibling::node()[1][self::text()]"/>
      </sqf:fix>
   </sqf:fixes>

   <!--<pattern id="LM-edit-no-SQFs">
      <let name="validation-top-limit" value="10"/>
      <let name="validation-bottom-limit" value="100"/>
      <rule context="tan:ana[parent::tan:group]">
         <let name="this-ana" value="."/>
         <let name="l-and-m-combos"
            value="
               for $i in tan:lm,
                  $j in $i/tan:l,
                  $k in $i/tan:m
               return
                  (count($i/preceding-sibling::tan:lm) + 1,
                  count($j/preceding-sibling::tan:l) + 1,
                  count($k/preceding-sibling::tan:m) + 1)"/>
         <!-\-<report test="count($l-and-m-combos) idiv 3 gt 1"> &lt;ana> has <value-of
               select="count($l-and-m-combos) idiv 3"/> l+m combos (<value-of
               select="
                  for $i in tan:lm,
                     $j in tan:expand-m($i/tan:m, true())
                  return
                     concat(string(number($j/@n) + count($i/preceding-sibling::tan:lm/tan:m)), ': ',
                     string-join($j/tan:feature[number(@count) lt max((count($i/tan:m), 2))]/@xml:id, ' '))"
            />) </report>-\->
      </rule>
      <rule context="tan:l[ancestor::tan:group]">
         <let name="fellow-ls" value="../../tan:lm/tan:l"/>
         <report test="count($fellow-ls) gt 1">Multiple &lt;l>s</report>
      </rule>
      <!-\-<rule context="tan:m[ancestor::tan:group]">
         <let name="fellow-ms" value="../../tan:lm/tan:m"/>
         <report test="count($fellow-ms) gt 1"><value-of
               select="tan:expand-m(., false())/tan:feature/@xml:id"/></report>
      </rule>-\->
   </pattern>-->
   <!--<pattern id="LM-edit-test">
      <rule context="tan:ana">
         <!-\-  delete-m-2 delete-m-3 -\->
         <report sqf:fix="delete-m-1" test="count(.//tan:m) gt 1">Multiple ms.</report>
         
      </rule>
   </pattern>-->
   <!--<pattern id="LM-edit-missing-ls">
      <!-\-<let name="master-lexicon"
         value="doc('../../../pre-TAN%20dev%20aids/pre-TAN-LM/grc/morphology%20grc.xml')"/>-\->
      <let name="master-lexicon" value="$empty-doc"/>
      <rule context="tan:l">
         <let name="this-token" value="comment()"/>
         <report test="not(text())">value missing</report>
         <report test="comment() and exists($master-lexicon)" sqf:fix="find-match">Master lexicon
            available to search on <value-of select="$this-token"/></report>
         <sqf:fix id="find-match">
            <sqf:description>
               <sqf:title>Find regex matches in master lexicon on <value-of select="$this-token"
                  /></sqf:title>
            </sqf:description>
            <let name="easier-search" value="tan:expand-search($this-token)"/>
            <let name="matches"
               value="$master-lexicon/*/tan:body/tan:e[tan:t[matches(., $easier-search, 'i')]]"/>
            <!-\-<sqf:add position="after" select="$matches/tan:l"></sqf:add>-\->
            <sqf:add match="." position="after">
               <!-\-<tan:l><value-of select="count($matches)"></value-of></tan:l>-\->
               <xsl:for-each-group select="$matches" group-by="tan:l">
                  <xsl:text>&#xA;</xsl:text>
                  <xsl:copy-of select="current-group()[1]/tan:l"/>
                  <xsl:for-each select="current-group()">
                     <xsl:text>&#xA;</xsl:text>
                     <xsl:copy-of select="tan:m"/>
                  </xsl:for-each>
               </xsl:for-each-group>
            </sqf:add>
         </sqf:fix>
      </rule>
   </pattern>-->
   <!--<pattern id="LM-core">
      <let name="has-source"
         value="
            if (/tan:TAN-LM/tan:head/tan:source) then
               true()
            else
               false()"/>
      <rule context="tan:tok">
         <let name="this-resolved" value="$empty-doc"/>
         <!-\-<report
            test="
               ($has-source = true()) and (some $i in $this-resolved
                  satisfies not($i/@ref))"
            > Any TAN-LM file with a source must have a @ref for every &lt;tok>. </report>-\->
         <!-\-<report
            test="
               ($has-source = false()) and (some $i in $this-resolved
                  satisfies $i/@ref)"
            > Any TAN-LM file without a source may not have @ref in any &lt;tok>. </report>-\->
         <!-\-<report
            test="
               ($has-source = false()) and (some $i in $this-resolved
                  satisfies $i/@pos)"
            > Any TAN-LM file without a source may not have @pos in any &lt;tok>. </report>-\->
         <!-\-<report
            test="
               ($has-source = false()) and (some $i in $this-resolved
                  satisfies $i/@chars)"
            > Any TAN-LM file without a source may not have @chars in any &lt;tok>. </report>-\->
      </rule>
   </pattern>-->
   <!--<pattern id="LM-edit-grouped-data">
      <!-\-<let name="features-grouped" value="tan:group-by-IRIs($mory-1st-da-resolved/tan:TAN-mor/tan:head/tan:declarations/tan:feature)"/>-\->
      <rule context="tan:ana[parent::tan:group]">
         <let name="this-ana" value="."/>
         <let name="l-and-m-combos"
            value="
               for $i in tan:lm,
                  $j in $i/tan:l,
                  $k in $i/tan:m
               return
                  (count($i/preceding-sibling::tan:lm) + 1,
                  count($j/preceding-sibling::tan:l) + 1,
                  count($k/preceding-sibling::tan:m) + 1)"/>
         <let name="ms-expanded" value="tan:expand-m(tan:lm/tan:m, true())"/>
         <let name="distinct-ms-per-lm"
            value="
               for $i in tan:lm
               return
                  ()"/>
         <report test="count($l-and-m-combos) idiv 3 gt 1"
            sqf:fix="delete-combo-1 delete-combo-2 delete-combo-3 delete-combo-1-globally delete-combo-2-globally delete-combo-3-globally delete-l-1 delete-l-2 delete-l-3 delete-l-1-globally delete-l-2-globally delete-l-3-globally delete-m-1 delete-m-2 delete-m-3 delete-m-1-globally delete-m-2-globally delete-m-3-globally"
            > &lt;ana> has <value-of select="count($l-and-m-combos) idiv 3"/> options (<value-of
               select="
                  for $i in tan:lm,
                     $j in tan:expand-m($i/tan:m, true())
                  return
                     concat(string(number($j/@n) + count($i/preceding-sibling::tan:lm/tan:m)), ': ',
                     string-join($j/tan:feature[number(@count) lt max((count($i/tan:m), 2))]/@xml:id, ' '))"
            />) </report>
         <sqf:fix id="delete-combo-1">
            <sqf:description>
               <sqf:title>Delete l-m combination 1</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-m-combo">
               <sqf:with-param name="this-l"
                  select="$this-ana/tan:lm[$l-and-m-combos[1]]/tan:l[$l-and-m-combos[2]]"/>
               <sqf:with-param name="this-m"
                  select="$this-ana/tan:lm[$l-and-m-combos[1]]/tan:m[$l-and-m-combos[3]]"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-combo-2" use-when="count($l-and-m-combos) ge 6">
            <sqf:description>
               <sqf:title>Delete l-m combination 2</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-m-combo">
               <sqf:with-param name="this-l"
                  select="$this-ana/tan:lm[$l-and-m-combos[4]]/tan:l[$l-and-m-combos[5]]"/>
               <sqf:with-param name="this-m"
                  select="$this-ana/tan:lm[$l-and-m-combos[4]]/tan:m[$l-and-m-combos[6]]"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-combo-3" use-when="count($l-and-m-combos) ge 9">
            <sqf:description>
               <sqf:title>Delete l-m combination 3</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-m-combo">
               <sqf:with-param name="this-l"
                  select="$this-ana/tan:lm[$l-and-m-combos[7]]/tan:l[$l-and-m-combos[8]]"/>
               <sqf:with-param name="this-m"
                  select="$this-ana/tan:lm[$l-and-m-combos[7]]/tan:m[$l-and-m-combos[9]]"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-combo-1-globally">
            <sqf:description>
               <sqf:title>Delete l + m combination 1 globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-l-m-combo-globally">
               <sqf:with-param name="this-l"
                  select="$this-ana/tan:lm[$l-and-m-combos[1]]/tan:l[$l-and-m-combos[2]]"/>
               <sqf:with-param name="this-m"
                  select="$this-ana/tan:lm[$l-and-m-combos[1]]/tan:m[$l-and-m-combos[3]]"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-combo-2-globally" use-when="count($l-and-m-combos) ge 6">
            <sqf:description>
               <sqf:title>Delete l + m combination 2 globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-l-m-combo-globally">
               <sqf:with-param name="this-l"
                  select="$this-ana/tan:lm[$l-and-m-combos[4]]/tan:l[$l-and-m-combos[5]]"/>
               <sqf:with-param name="this-m"
                  select="$this-ana/tan:lm[$l-and-m-combos[4]]/tan:m[$l-and-m-combos[6]]"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-combo-3-globally" use-when="count($l-and-m-combos) ge 9">
            <sqf:description>
               <sqf:title>Delete l + m combination 3 globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-l-m-combo-globally">
               <sqf:with-param name="this-l"
                  select="$this-ana/tan:lm[$l-and-m-combos[7]]/tan:l[$l-and-m-combos[8]]"/>
               <sqf:with-param name="this-m"
                  select="$this-ana/tan:lm[$l-and-m-combos[7]]/tan:m[$l-and-m-combos[9]]"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-chosen-l-m-combo">
            <sqf:param name="this-l" type="element()"/>
            <sqf:param name="this-m" type="element()"/>
            <let name="this-lm" value="$this-l/.."/>
            <sqf:description>
               <sqf:title>Replace a chosen l + m combo</sqf:title>
            </sqf:description>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) eq 1"
               match="$this-lm, $this-lm/following-sibling::node()[1][self::text()]"/>
            <sqf:delete use-when="count($this-lm/tan:l) gt 1 and count($this-lm/tan:m) eq 1"
               match="$this-l, $this-l/following-sibling::node()[1][self::text()]"/>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) gt 1"
               match="$this-m, $this-m/following-sibling::node()[1][self::text()]"/>
         </sqf:fix>
         <sqf:fix id="delete-l-m-combo-globally">
            <sqf:param name="this-l" type="element()"/>
            <sqf:param name="this-m" type="element()"/>
            <let name="all-matches" value="tan:get-matching-lm-combos($this-l, $this-m)"/>
            <sqf:description>
               <sqf:title>Replace chosen l + m combo globally</sqf:title>
            </sqf:description>
            <sqf:delete
               match="$all-matches, $all-matches/following-sibling::node()[1][self::text()]"/>
         </sqf:fix>
         <sqf:fix id="delete-l-1">
            <let name="this-l" value="(.//tan:l)[1]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-l"/></sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m">
               <sqf:with-param name="l-or-m-element" select="$this-l"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-l-2" use-when="count(.//tan:l) gt 1">
            <let name="this-l" value="(.//tan:l)[2]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-l"/></sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m">
               <sqf:with-param name="l-or-m-element" select="$this-l"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-l-3" use-when="count(.//tan:l) gt 2">
            <let name="this-l" value="(.//tan:l)[3]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-l"/></sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m">
               <sqf:with-param name="l-or-m-element" select="$this-l"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-l-1-globally">
            <let name="this-l" value="(.//tan:l)[1]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-l"/> globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m-globally">
               <sqf:with-param name="l-or-m-element" select="$this-l"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-l-2-globally" use-when="count(.//tan:l) gt 1">
            <let name="this-l" value="(.//tan:l)[2]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-l"/> globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m-globally">
               <sqf:with-param name="l-or-m-element" select="$this-l"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-l-3-globally" use-when="count(.//tan:l) gt 2">
            <let name="this-l" value="(.//tan:l)[3]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-l"/> globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m-globally">
               <sqf:with-param name="l-or-m-element" select="$this-l"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-m-1">
            <let name="this-m" value="(.//tan:m)[1]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-m"/></sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m">
               <sqf:with-param name="l-or-m-element" select="$this-m"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-m-2" use-when="count(.//tan:m) gt 1">
            <let name="this-m" value="(.//tan:m)[2]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-m"/></sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m">
               <sqf:with-param name="l-or-m-element" select="$this-m"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-m-3" use-when="count(.//tan:m) gt 2">
            <let name="this-m" value="(.//tan:m)[3]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-m"/></sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m">
               <sqf:with-param name="l-or-m-element" select="$this-m"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-m-1-globally">
            <let name="this-m" value="(.//tan:m)[1]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-m"/> globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m-globally">
               <sqf:with-param name="l-or-m-element" select="$this-m"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-m-2-globally" use-when="count(.//tan:m) gt 1">
            <let name="this-m" value="(.//tan:m)[2]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-m"/> globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m-globally">
               <sqf:with-param name="l-or-m-element" select="$this-m"/>
            </sqf:call-fix>
         </sqf:fix>
         <sqf:fix id="delete-m-3-globally" use-when="count(.//tan:m) gt 2">
            <let name="this-m" value="(.//tan:m)[3]"/>
            <sqf:description>
               <sqf:title>Delete <value-of select="$this-m"/> globally</sqf:title>
            </sqf:description>
            <sqf:call-fix ref="delete-chosen-l-or-m-globally">
               <sqf:with-param name="l-or-m-element" select="$this-m"/>
            </sqf:call-fix>
         </sqf:fix>
      </rule>
   </pattern>-->
   <!--<let name="morphology-ids" value="/tan:TAN-LM/tan:head/tan:declarations/tan:morphology/@xml:id"/>
   <let name="morphologies-1st-loc-avail"
      value="/tan:TAN-LM/tan:head/tan:declarations/tan:morphology/tan:location[doc-available(resolve-uri(@href,$doc-uri))][1]"/>
   <let name="morphologies"
      value="for $i in $morphologies-1st-loc-avail
         return
            doc(resolve-uri($i,$doc-uri))"/>-->
   <!--<pattern id="LM-quarter">
      <!-\-<rule context="tan:morphology">
         <report test="true()"><xsl:value-of select="$morphologies-1st-la"></xsl:value-of></report>
      </rule>-\->
      <rule context="tan:ana">
         <let name="single-tok-test"
            value="
               if (@xml:id) then
                  count((tan:tok,
                  tan:joined)) + count(tan:tok/@ref[matches(., '\s+[,-]\s+')]) + count(tan:tok/@pos[matches(., '\s*[,-]\s+')])
               else
                  ()"/>
         <!-\-<report test="$single-tok-test gt 1">Any ana with an @xml:id must point to no more than one
            token.</report>-\->
      </rule>
      <rule context="tan:tok">
         <!-\-<report test="@cont = 'false'" role="warning">@cont with the value 'false' will still be
            treated as true. If you do not wish a &lt;tok> to be continued, delete this
            attribute.</report>-\->
      </rule>
      <rule context="tan:m">
         <let name="this" value="."/>
         <let name="this-val" value="tokenize(lower-case(.), '\s+')"/>
         <let name="this-mory-id" value="(ancestor-or-self::*/@morphology)[1]"/>
         <let name="this-mory" value="$morphologies-1st-da[$this-mory-id]"/>
         <let name="this-morph-cat-qty"
            value="
               if ($this-mory//tan:category) then
                  count($this-mory//tan:category)
               else
                  ()"/>

         <let name="invalid-codes"
            value="
               if (exists($this-morph-cat-qty)) then
                  for $i in (1 to count($this-val))
                  return
                     if ($this-val[$i] = '-') then
                        ()
                     else
                        if ($this-val[$i] = (for $j in $this-mory//tan:category[$i]/tan:option/@code
                        return
                           lower-case($j))) then
                           ()
                        else
                           $i
               else
                  for $i in $this-val
                  return
                     if ($i = (for $j in $this-mory//(@code,
                     tan:feature/@xml:id)
                     return
                        lower-case($j))) then
                        ()
                     else
                        $i"/>
         <let name="reports"
            value="$this-mory//tan:report[$this-val = tokenize(lower-case(@context), '\s+')], $this-mory//tan:report[not(@context)]"/>
         <let name="asserts"
            value="$this-mory//tan:assert[$this-val = tokenize(lower-case(@context), '\s+')], $this-mory//tan:assert[not(@context)]"/>
         <let name="feature-qty-test"
            value="
               for $i in $reports[@feature-qty-test]
               return
                  if (count($this-val[. = (tan:all-morph-codes($this-mory, tokenize($i/@context, '\s+')))]) ge number($i/@feature-qty-test))
                  then
                     $i
                  else
                     (),
               for $i in $asserts[@feature-qty-test]
               return
                  if (not(count($this-val[. = (tan:all-morph-codes($this-mory, tokenize($i/@context, '\s+')))]) ge number($i/@feature-qty-test)))
                  then
                     $i
                  else
                     ()"/>
         <let name="matches-m"
            value="
               for $i in $reports[@matches-m]
               return
                  if (matches($this, $i/@matches-m, 'i'))
                  then
                     $i
                  else
                     (),
               for $i in $asserts[@matches-m]
               return
                  if (not(matches($this, $i/@matches-m, 'i')))
                  then
                     $i
                  else
                     ()"/>
         <let name="feature-test"
            value="
               for $i in $reports[@feature-test]
               return
                  if (tan:feature-test-check($this, $i/@feature-test, $this-mory))
                  then
                     $i
                  else
                     (),
               for $i in $asserts[@feature-test]
               return
                  if (not(tan:feature-test-check($this, $i/@feature-test, $this-mory)))
                  then
                     $i
                  else
                     ()"/>
         <let name="all-tests" value="$feature-qty-test, $matches-m, $feature-test"/>
         <!-\-<report
            test="
               if (exists($this-morph-cat-qty)) then
                  count($this-val) gt $this-morph-cat-qty
               else
                  ()"
            >&lt;m> may not have more codes than allowed by the underlying TAN-R-mor file.</report>-\->
         <!-\-<report test="exists($invalid-codes) and not(exists($this-morph-cat-qty))"
            ><!-\\- If any invalid values are found during validation a list of possible valid values will be returned. -\\->Invalid
            value(s) (<value-of select="$invalid-codes"/>); valid values: <value-of
               select="$features-grouped/tan:feature[@src = $this-mory-id]/(@code, @xml:id)"
            /></report>-\->
         <!-\-<report test="exists($invalid-codes) and exists($this-morph-cat-qty)"
            ><!-\\- If an invalid code is found in a particular location, a list of valid values for that location will be returned -\\->Invalid
            codes at position(s) <value-of select="$invalid-codes"/>; valid values: <value-of
               select="
                  for $i in $invalid-codes
                  return
                     concat('[', string($i), ': ', string-join(for $j in $this-mory//tan:category[$i]/tan:option
                     return
                        concat($j/@code, ' (', $j/@feature, ') '),
                     ' '), '] ')"
            /></report>-\->
         <!-\-<report test="exists($all-tests[@cert])" role="warning"
               ><!-\\- If <m> matches a rule in the underlying TAN-R-mor file that is qualified by some uncertainty, the element will be marked as valid, but a warning will be returned -\\-><value-of
               select="
                  for $i in $all-tests[@cert]
                  return
                     concat('Confidence ', $i/@cert, ' : ', $i/text())"
            /></report>-\->
         <!-\-<report test="exists($all-tests[not(@cert)])">All codes must adhere to the rules declared
            in the underlying TAN-R-mor file (<xsl:value-of select="$all-tests[not(@cert)]/text()"
            />)</report>-\->
      </rule>
   </pattern>-->
   <pattern id="LM-half"/>
   <pattern id="LM-full"/>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-LM-functions.xsl"/>

</schema>
