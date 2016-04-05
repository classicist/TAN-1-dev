<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   queryBinding="xslt2">
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
   <include href="TAN-class-2-edit.sch"/>
   <include href="TAN-class-2-quarter.sch"/>
   <include href="TAN-class-2-half.sch"/>
   <include href="TAN-class-2-full.sch"/>
   <phase id="edit">
      <active pattern="class-2-edit"/>
      <active pattern="LM-edit"/>
   </phase>
   <phase id="quarter">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="LM-quarter"/>
   </phase>
   <phase id="half">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="LM-quarter"/>
      <active pattern="LM-half"/>
   </phase>
   <phase id="full">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="class-2-full"/>
      <active pattern="LM-quarter"/>
      <active pattern="LM-half"/>
      <active pattern="LM-full"/>
   </phase>

   <pattern id="LM-edit">
      <!--<let name="features-grouped" value="tan:group-by-IRIs($mory-1st-da-resolved/tan:TAN-mor/tan:head/tan:declarations/tan:feature)"/>-->
      <rule context="tan:ana">
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
         <report test="count($l-and-m-combos) idiv 3 gt 1" sqf:fix="delete-1 delete-2 delete-3">
            &lt;ana> has <value-of select="count($l-and-m-combos) idiv 3"/> options (<value-of
               select="
                  for $i in tan:lm,
                     $j in tan:expand-m($i/tan:m, true())
                  return
                     concat(string(number($j/@n) + count($i/preceding-sibling::tan:lm/tan:m)), ': ', 
                     string-join($j/tan:feature[number(@count) lt max((count($i/tan:m), 2))]/@xml:id, ' '))"
            />) </report>
         <sqf:fix id="delete-1">
            <sqf:description>
               <sqf:title>Delete l-m combination 1</sqf:title>
            </sqf:description>
            <let name="this-lm" value="$this-ana/tan:lm[$l-and-m-combos[1]]"/>
            <let name="this-l" value="$this-lm/tan:l[$l-and-m-combos[2]]"/>
            <let name="this-m" value="$this-lm/tan:m[$l-and-m-combos[3]]"/>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) eq 1"
               match="$this-lm, $this-lm/following-sibling::node()[1][self::text()]"/>
            <sqf:delete use-when="count($this-lm/tan:l) gt 1 and count($this-lm/tan:m) eq 1"
               match="$this-l, $this-l/following-sibling::node()[1][self::text()]"/>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) gt 1"
               match="$this-m, $this-m/following-sibling::node()[1][self::text()]"/>
         </sqf:fix>
         <sqf:fix id="delete-2" use-when="count($l-and-m-combos) ge 6">
            <sqf:description>
               <sqf:title>Delete l-m combination 2</sqf:title>
            </sqf:description>
            <let name="this-lm" value="$this-ana/tan:lm[$l-and-m-combos[4]]"/>
            <let name="this-l" value="$this-lm/tan:l[$l-and-m-combos[5]]"/>
            <let name="this-m" value="$this-lm/tan:m[$l-and-m-combos[6]]"/>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) eq 1"
               match="$this-lm"/>
            <sqf:delete use-when="count($this-lm/tan:l) gt 1 and count($this-lm/tan:m) eq 1"
               match="$this-l"/>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) gt 1"
               match="$this-m"/>
         </sqf:fix>
         <sqf:fix id="delete-3" use-when="count($l-and-m-combos) ge 9">
            <sqf:description>
               <sqf:title>Delete l-m combination 3</sqf:title>
            </sqf:description>
            <let name="this-lm" value="$this-ana/tan:lm[$l-and-m-combos[7]]"/>
            <let name="this-l" value="$this-lm/tan:l[$l-and-m-combos[8]]"/>
            <let name="this-m" value="$this-lm/tan:m[$l-and-m-combos[9]]"/>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) eq 1"
               match="$this-lm"/>
            <sqf:delete use-when="count($this-lm/tan:l) gt 1 and count($this-lm/tan:m) eq 1"
               match="$this-l"/>
            <sqf:delete use-when="count($this-lm/tan:l) eq 1 and count($this-lm/tan:m) gt 1"
               match="$this-m"/>
         </sqf:fix>
      </rule>
   </pattern>
   <!--<let name="morphology-ids" value="/tan:TAN-LM/tan:head/tan:declarations/tan:morphology/@xml:id"/>
   <let name="morphologies-1st-loc-avail"
      value="/tan:TAN-LM/tan:head/tan:declarations/tan:morphology/tan:location[doc-available(resolve-uri(@href,$doc-uri))][1]"/>
   <let name="morphologies"
      value="for $i in $morphologies-1st-loc-avail
         return
            doc(resolve-uri($i,$doc-uri))"/>-->
   <pattern id="LM-quarter">
      <!--<rule context="tan:morphology">
         <report test="true()"><xsl:value-of select="$morphologies-1st-la"></xsl:value-of></report>
      </rule>-->
      <rule context="tan:ana">
         <let name="single-tok-test"
            value="
               if (@xml:id) then
                  count((tan:tok,
                  tan:joined)) + count(tan:tok/@ref[matches(., '\s+[,-]\s+')]) + count(tan:tok/@pos[matches(., '\s*[,-]\s+')])
               else
                  ()"/>
         <report test="$single-tok-test gt 1">Any ana with an @xml:id must point to no more than one
            token.</report>
      </rule>
      <rule context="tan:tok">
         <report test="@cont = 'false'" role="warning">@cont with the value 'false' will still be
            treated as true. If you do not wish a &lt;tok> to be continued, delete this
            attribute.</report>
      </rule>
      <rule context="tan:m">
         <let name="this" value="."/>
         <let name="this-val" value="tokenize(lower-case(.), '\s+')"/>
         <let name="this-mory-id" value="(ancestor-or-self::*/@morphology)[1]"/>
         <let name="this-mory" value="$mory-1st-da-resolved[$this-mory-id]"/>
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
            value="$this-mory//tan:report[$this-val = tokenize(lower-case(@feature-filter), '\s+')], $this-mory//tan:report[not(@feature-filter)]"/>
         <let name="asserts"
            value="$this-mory//tan:assert[$this-val = tokenize(lower-case(@feature-filter), '\s+')], $this-mory//tan:assert[not(@feature-filter)]"/>
         <let name="feature-qty-test"
            value="
               for $i in $reports[@feature-qty-test]
               return
                  if (count($this-val[. = (tan:all-morph-codes($this-mory, tokenize($i/@feature-filter, '\s+')))]) ge number($i/@feature-qty-test))
                  then
                     $i
                  else
                     (),
               for $i in $asserts[@feature-qty-test]
               return
                  if (not(count($this-val[. = (tan:all-morph-codes($this-mory, tokenize($i/@feature-filter, '\s+')))]) ge number($i/@feature-qty-test)))
                  then
                     $i
                  else
                     ()"/>
         <let name="code-regex-test"
            value="
               for $i in $reports[@code-regex-test]
               return
                  if (matches($this, $i/@code-regex-test, 'i'))
                  then
                     $i
                  else
                     (),
               for $i in $asserts[@code-regex-test]
               return
                  if (not(matches($this, $i/@code-regex-test, 'i')))
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
         <let name="all-tests" value="$feature-qty-test, $code-regex-test, $feature-test"/>
         <report
            test="
               if (exists($this-morph-cat-qty)) then
                  count($this-val) gt $this-morph-cat-qty
               else
                  ()"
            >&lt;m> may not have more codes than allowed by the underlying TAN-R-mor file.</report>
         <report test="exists($invalid-codes) and not(exists($this-morph-cat-qty))"
            ><!-- If any invalid values are found during validation a list of possible valid values will be returned. -->Invalid
            value(s) (<value-of select="$invalid-codes"/>); valid values: <value-of
               select="$features-grouped/tan:feature[@src = $this-mory-id]/(@code, @xml:id)"
            /></report>
         <report test="exists($invalid-codes) and exists($this-morph-cat-qty)"
            ><!-- If an invalid code is found in a particular location, a list of valid values for that location will be returned -->Invalid
            codes at position(s) <value-of select="$invalid-codes"/>; valid values: <value-of
               select="
                  for $i in $invalid-codes
                  return
                     concat('[', string($i), ': ', string-join(for $j in $this-mory//tan:category[$i]/tan:option
                     return
                        concat($j/@code, ' (', $j/@feature, ') '),
                     ' '), '] ')"
            /></report>
         <report test="exists($all-tests[@cert])" role="warning"
               ><!-- If <m> matches a rule in the underlying TAN-R-mor file that is qualified by some uncertainty, the element will be marked as valid, but a warning will be returned --><value-of
               select="
                  for $i in $all-tests[@cert]
                  return
                     concat('Confidence ', $i/@cert, ' : ', $i/text())"
            /></report>
         <report test="exists($all-tests[not(@cert)])">All codes must adhere to the rules declared
            in the underlying TAN-R-mor file (<xsl:value-of select="$all-tests[not(@cert)]/text()"
            />)</report>
      </rule>
   </pattern>
   <pattern id="LM-half"/>
   <pattern id="LM-full"/>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-LM-functions.xsl"/>

</schema>
