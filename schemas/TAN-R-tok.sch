<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process" queryBinding="xslt2">
   <title>Tests for TAN-R-tok files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <!-- common core below -->
   <include href="TAN-core.sch"/>
   <include href="TAN-class-3.sch"/>
   <pattern>
      <let name="replace" value="$body/tan:replace"/>
      <let name="tokenize" value="$body/tan:tokenize"/>
      <rule context="tan:example">
         <let name="input" value="tan:input"/>
         <let name="output" value="tan:output-token"/>
         <let name="input-replace"
            value="if (exists($replace)) then
                  tan:replace-sequence($input, $replace)
               else
                  $input"/>
         <let name="expected-output" value="tan:tokenize($input-replace, $tokenize)"/>
         <let name="matches"
            value="for $i in (1 to count($expected-output))
               return
                  ($expected-output[$i] = $output[$i])"/>
         <!-- START TESTING BLOCK -->
         <let name="test1" value="$output"/>
         <let name="test2" value="$expected-output"/>
         <let name="test3" value="$matches"/>
         <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
               select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
         <!-- END TESTING BLOCK -->
         <assert sqf:fix="correct-output"
            test="every $i in $matches
            satisfies $i = true() and count($output) = count($expected-output)"
            >Input must match output <xsl:choose>
               <xsl:when test="$matches = false()">(output-token <xsl:value-of
                     select="index-of($matches, false())"/>; expected: "<xsl:value-of
                     select="
                        string-join(for $i in index-of($matches, false())
                        return
                           $expected-output[$i], '&quot;, &quot;')"
                  />")</xsl:when>
               <xsl:when test="count($output) != count($expected-output)"> (<xsl:value-of
                     select="count($output)"/> output-token elements; expected <xsl:value-of
                     select="count($expected-output)"/>) </xsl:when>
            </xsl:choose></assert>
         <sqf:fix id="correct-output">
            <sqf:description>
               <sqf:title>Correct &lt;output-token&gt; elements</sqf:title>
               <sqf:p>Selecting this quick fix will replace all &lt;example-output> elements with the correct results.</sqf:p>
            </sqf:description>
            <sqf:replace match="tan:output-token"/>
            <sqf:replace match="text()[preceding-sibling::tan:input]"/>
            <sqf:add match="." position="last-child">
               <xsl:for-each select="$expected-output"><xsl:element name="output-token"><value-of
                        select="."/></xsl:element></xsl:for-each>
            </sqf:add>
         </sqf:fix>
      </rule>
   </pattern>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-R-tok-functions.xsl"/>
   
</schema>
