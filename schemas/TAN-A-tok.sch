<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-A-tok files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>

   <!-- common core below -->
   <include href="TAN-core.sch"/>
   <include href="TAN-class-2.sch"/>
   <pattern xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
      <let name="head-inclusion" value="/tan:TAN-A-tok/tan:head/tan:inclusion[@xml:id = following-sibling::tan:source/@include]"/>
      <let name="incl-1st-loc-avail" value="tan:first-loc-available($head-inclusion)/@href"/>
      <let name="incl-1st-da" value="doc(resolve-uri($incl-1st-loc-avail, $doc-uri))"/>
      <let name="incl-1st-da-resolved" value="tan:resolve-doc($incl-1st-da)"/>
      <rule context="tan:declarations">
         <let name="children-names" value="for $i in * return name($i)"/>
         <let name="incl-declarations"
            value="distinct-values(for $i in $incl-1st-da-resolved//tan:declarations/*
               return
                  name($i))"/>
         <let name="missing-declarations" value="$incl-declarations[not(. = $children-names)]"/>
         <!-- START TESTING BLOCK -->
         <let name="test1" value="$children-names"/>
         <let name="test2" value="$missing-declarations"/>
         <let name="test3" value="true()"/>
         <report test="false()">Testing. var1: <value-of select="$test1"/> var2: <value-of
               select="$test2"/> var3: <value-of select="$test3"/></report>
         <!-- END TESTING BLOCK -->
         <!--<assert
            test="every $i in $incl-declarations
                  satisfies *[name(.) = $i]"
            >Every declaration invoked by the head inclusion must be repeated here (<value-of
               select="$incl-declarations"/>)</assert>-->
         <report test="exists($missing-declarations) and exists($head-inclusion)"
            sqf:fix="add-declaration">In a TAN-A-tok file, if there is a source/@include, then an
            entire set of sources are being imported, and, consequently, every declaration in the
            inclusion must also be included (missing: <value-of select="$missing-declarations"
            />)</report>
         <sqf:fix id="add-declaration">
            <sqf:description>
               <sqf:title>Add declaration</sqf:title>
               <sqf:p>Choosing this option will insert the first missing child of the declarations
                  element. If multiple declarations are missing, repeat as needed.</sqf:p>
            </sqf:description>
            <sqf:add target="{$missing-declarations[1]}" node-type="element" match="."
               position="first-child" select="//tan:source[1]/@include">
            </sqf:add>
         </sqf:fix>
         <!--<report test="$first-incl-doc-resolved//tan:rename-div-ns and not(tan:rename-div-ns[@include])">The source 
            document renames the div @n's. That declaration should be included here as well.
         </report>-->
      </rule>
      <rule context="*[parent::tan:declarations]">
         <report test="exists($head-inclusion) and not(@include)" sqf:fix="replace-with-inclusion"
            tan:does-not-apply-to="declarations">In a TAN-A-tok file, if there is a source/@include,
            then an entire set of sources are being imported, and, consequently, every declaration
            in the inclusion must also be included. </report>
         <sqf:fix id="replace-with-inclusion">
            <sqf:description>
               <sqf:title>Replace with inclusion</sqf:title>
               <sqf:p>Choosing this option will replace a child element of declarations with one 
                  that specifies @include to point to the value of source/@include</sqf:p>
            </sqf:description>
            <sqf:delete match="*"/>
            <sqf:delete match="@*"/>
            <sqf:add match="." node-type="attribute"
               target="include"><value-of select="$head-inclusion/@xml:id"/></sqf:add>
         </sqf:fix>
      </rule>
   </pattern>
   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-tok-functions.xsl"/>
</schema>
