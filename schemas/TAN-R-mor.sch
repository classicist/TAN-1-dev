<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process" queryBinding="xslt2">
   <title>Tests for TAN-R-mor files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <!-- common core below -->
   <include href="TAN-core.sch"/>
   <include href="TAN-class-3.sch"/>
   <pattern>
      <let name="feature-incl-refs" value="for $i in $head/tan:declarations/tan:feature/@include return tokenize($i,'\s+')"/>
      <let name="feature-inclusion" value="$head/tan:inclusion[@xml:id = $feature-incl-refs]"/>
      <let name="incl-1st-loc-avail" value="for $i in $feature-inclusion return tan:first-loc-available($i)"/>
      <let name="incl-1st-da" value="for $i in $incl-1st-loc-avail return doc(resolve-uri($i, $doc-uri))"/>
      <let name="incl-1st-da-resolved" value="for $i in $incl-1st-da return tan:resolve-doc($i)"/>
      <rule context="tan:feature">
         <let name="these-inclusions" value="tokenize(@include,'\s+')"/>
         <let name="these-langs" value="$head/tan:declarations/tan:for-lang"/>
         <let name="langs-not-supported-by-inclusion" value="for $i in $these-inclusions, $j in index-of($feature-incl-refs,$i), $k in $these-langs return
            if ($incl-1st-da-resolved[$j]//tan:for-lang[. = $k]) then () else $k"/>
         <report test="exists($langs-not-supported-by-inclusion)">Included features must be written for every language declared by
         the current file (<value-of select="$langs-not-supported-by-inclusion"/>).</report>
      </rule>
      <rule context="@code">
         <let name="code" value="."/>
         <let name="other-codes"
            value="for $i in ../(preceding-sibling::tan:option,
               following-sibling::tan:option)/@code
               return
                  lower-case($i)"/>
         <assert test="count(../../tan:option[@code = $code]) = 1">The value of @code must be unique
            within a given category</assert>
         <report test="lower-case($code) = $other-codes">Codes may not duplicate or be a case
            variant of each other.</report>
         <report test="//tan:feature[lower-case(@xml:id) = lower-case($code)]">No code may repeat an
            id of a feature</report>
      </rule>
      <rule context="@feature-test">
         <let name="this" value="tan:normalize-feature-test(.)"/>
         <let name="this-seq" value="tan:feature-test-seq($this, 0)"/>
         <let name="this-features"
            value="for $i in $this-seq
               return
                  if ($i instance of xs:integer) then
                     ()
                  else
                     if (matches($i, '[,\|]')) then
                        ()
                     else
                        $i"/>
         <let name="invalid-features"
            value="for $i in $this-features
               return
                  if (//@code[lower-case(.) = lower-case($i)] or $head//tan:feature[lower-case(@xml:id) = lower-case($i)]) then
                     ()
                  else
                     $i"/>
         <!-- START TESTING BLOCK -->
         <let name="test1" value="$this-features"/>
         <let name="test2" value="$invalid-features"/>
         <let name="test3" value="true()"/>
         <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
               select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
         <!-- END TESTING BLOCK -->
         <report test="matches($this,'^[,|]|[,|]$')">@feature-test may not begin or end with an
            operator</report>
         <!-- to be written -->
         <report test="false()">Operators may not be mixed within a group</report>
         <report test="matches($this,'[,|] [,|]')">Operators must separate groups or feature
            refs.</report>
         <report test="matches($this,'[^\(\),|]+ [^\(\),|]+')">Feature refs must be separated by
            operators | or ,</report>
         <!-- to be written -->
         <report test="false()">Feature refs must refer to @code or feature/@xml:id values.</report>
         <report
            test="count(for $i in $this-seq return if ($i instance of xs:integer) then $i else ()) mod 2 = 1"
            >Parentheses in @feature-test must be balanced.</report>
         <report test="matches($this,'[^\(\),|]+ \(|\) [^\(\),|]+')">Feature references and
            parentheses must be separated by a pipe operator: |</report>
         <report test="exists($invalid-features)"><!-- Must refer to <feature>s in the <declarations> -->The feature(s) <value-of
               select="string-join($invalid-features, ', ')"/> have not been declared.</report>
      </rule>
      <rule context="@feature-filter">
         <let name="this-seq" value="tokenize(lower-case(.), '\s+')"/>
         <let name="invalid-features"
            value="for $i in $this-seq
               return
                  if (//@code[lower-case(.) = $i] or $head//tan:feature[lower-case(@xml:id) = $i]) then
                     ()
                  else
                     $i"/>
         <report test="exists($invalid-features)"><!-- Must refer to <feature>s in the <declarations> -->The feature(s) <value-of
               select="string-join($invalid-features, ', ')"/> have not been declared.</report>
      </rule>
      <rule context="@feature-qty-test">
         <let name="ff" value="../@feature-filter"/>
         <let name="this" value="number(.)"/>
         <assert test="exists($ff)">@feature-qty-test requires @feature-filter.</assert>
         <report test="($this lt 2) or ($this gt count(tokenize($ff,'\s+')))">@feature-qty-test must
            neither be less than two nor greater than the number of features in
            @feature-filter.</report>
      </rule>

      <!-- FUNCTIONS -->
      <xsl:include href="../functions/TAN-R-mor-functions.xsl"/>

   </pattern>
</schema>
