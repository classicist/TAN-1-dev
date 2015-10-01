<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-LM files.</title>
   <!-- to do: 
      Check @only-if-has-features to make sure it matches either a @code or feature/@xml:id 
      invalid patterns plus warning from TAN-R-mor file
      Make sure that <joined> combines two or more tokens
      l may be left empty, indicating that the value of the word tokens must be used. In this case, all values of tok must resolve to the same value, or a validation error will result.
   -->
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <include href="TAN-core.sch"/>
   <include href="TAN-class-2.sch"/>
   <!--<let name="morphology-ids" value="/tan:TAN-LM/tan:head/tan:declarations/tan:morphology/@xml:id"/>
   <let name="morphologies-1st-loc-avail"
      value="/tan:TAN-LM/tan:head/tan:declarations/tan:morphology/tan:location[doc-available(resolve-uri(.,$doc-uri))][1]"/>
   <let name="morphologies"
      value="for $i in $morphologies-1st-loc-avail
         return
            doc(resolve-uri($i,$doc-uri))"/>-->
   <pattern>
      <rule context="tan:lm">
         <report test="not(tan:l|tan:m)">lm must take at least one l or m.</report>
      </rule>
      <rule context="tan:ana">
         <let name="single-tok-test"
            value="if (@xml:id) then
                  count((tan:tok,
                  tan:joined)) + count(tan:tok/@ref[matches(., '\s+[,-]\s+')]) + count(tan:tok/@ord[matches(., '\s*[,-]\s+')])
               else
                  ()"/>
         <report test="$single-tok-test gt 1">Any ana with an @xml:id must point to no more than one
            token.</report>
      </rule>
      <rule context="tan:m">
         <let name="this" value="."/>
         <let name="this-val" value="tokenize(lower-case(.), '\s+')"/>
         <let name="this-mory-no" value="index-of($morphologies/@xml:id, ($this/ancestor-or-self::node()/@morphology)[last()])[1]"/>
         <let name="this-mory" value="$mory-1st-da-resolved[$this-mory-no]"/>
         <let name="this-morph-cat-qty"
            value="if ($this-mory//tan:category) then
                  count($this-mory//tan:category)
               else
                  ()"/>
         
         <let name="invalid-codes"
            value="if (exists($this-morph-cat-qty)) then
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
         <let name="reports" value="$this-mory//tan:report[$this-val = tokenize(lower-case(@feature-filter),'\s+')], $this-mory//tan:report[not(@feature-filter)]"/>
         <let name="asserts" value="$this-mory//tan:assert[$this-val = tokenize(lower-case(@feature-filter),'\s+')], $this-mory//tan:assert[not(@feature-filter)]"/>
         <let name="filter-qty-test" value="for $i in $reports[@filter-qty-test] return
            if (count($this-val[. = (tan:all-morph-codes($this-mory,tokenize($i/@feature-filter,'\s+')))]) ge number($i/@filter-qty-test))
            then $i
            else (), for $i in $asserts[@filter-qty-test] return
            if (not(count($this-val[. = (tan:all-morph-codes($this-mory,tokenize($i/@feature-filter,'\s+')))]) ge number($i/@filter-qty-test)))
            then $i
            else ()"></let>
         <let name="code-regex-test" value="for $i in $reports[@code-regex-test] return 
            if (matches($this,$i/@code-regex-test,'i'))
            then $i
            else (), for $i in $asserts[@code-regex-test] return 
            if (not(matches($this,$i/@code-regex-test,'i')))
            then $i
            else ()"/>
         <let name="feature-test" value="for $i in $reports[@feature-test] return
            if(tan:feature-test-check($this,$i/@feature-test,$this-mory))
            then $i
            else (), for $i in $asserts[@feature-test] return
            if(not(tan:feature-test-check($this,$i/@feature-test,$this-mory)))
            then $i
            else ()"/>
         <let name="all-tests" value="$filter-qty-test, $code-regex-test, $feature-test"/>
         <!-- START TESTING BLOCK -->
         <let name="test1" value="index-of($morphologies/@xml:id, ($this/ancestor-or-self::node()/@morphology)[1])"/>
         <let name="test2" value="($this/ancestor-or-self::node()/@morphology)[last()]"/>
         <let name="test3" value="$all-tests"/>
         <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
               select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
         <!-- END TESTING BLOCK -->
         <report
            test="if (exists($this-morph-cat-qty)) then count($this-val) gt $this-morph-cat-qty else ()"
            >M has too many codes</report>
         <report test="exists($invalid-codes) and not(exists($this-morph-cat-qty))">Invalid value(s)
               (<value-of select="$invalid-codes"/>); valid values: <value-of
               select="$mory-1st-da-features[$this-mory-no]/tan:feature/(tan:option/@code,
                  @xml:id)"
            /></report>
         <report test="exists($invalid-codes) and exists($this-morph-cat-qty)">Invalid codes at position(s) 
            <value-of select="$invalid-codes"/>; valid values: <value-of select="for $i in $invalid-codes return
               concat('[',string($i),': ',string-join(for $j in $this-mory//tan:category[$i]/tan:option return 
               concat($j/@code,' (',$j/@feature,') '),
               ' '),'] ')"/></report>
         <report test="exists($all-tests[@cert])" role="warning"><value-of select="for $i in $all-tests[@cert] return
            concat('Confidence ',$i/@cert,' : ',$i/text())"/></report>
         <report test="exists($all-tests[not(@cert)])">Error: <xsl:value-of select="$all-tests[not(@cert)]/text()"/></report>
      </rule>
      
      <!-- FUNCTIONS -->
      <xsl:include href="../functions/TAN-LM-functions.xsl"/>
      
   </pattern>
</schema>
