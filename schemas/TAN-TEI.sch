<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
   <title>Tests for TAN-TEI files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <!-- common core below -->
   <include href="TAN-core.sch"/>
   <include href="TAN-class-1.sch"/>
   <pattern>
      <let name="ids" value="//@xml:id"></let>
      <rule context="@xml:id">
         <assert test="count(index-of($ids,.)) = 1">@xml:id assignments must be unique</assert>
      </rule>
      <rule context="@ed-when | @ed-who">
         <assert test="../@ed-when and ../@ed-who">Neither @ed-when nor @ed-who may appear
            alone.</assert>
      </rule>
      <rule context="@when-iso">
         <report role="warn" test=". = ''" sqf:fix="insert-todays-date insert-current-dateTime">@iso-when should not be
            empty.</report>
         <sqf:fix id="insert-todays-date">
            <sqf:description>
               <sqf:title>Insert today's date (ISO)</sqf:title>
            </sqf:description>
            <sqf:replace match="." target="when-iso" node-type="attribute">
               <value-of select="current-date()"/>
            </sqf:replace>
         </sqf:fix>
         <sqf:fix id="insert-current-dateTime">
            <sqf:description>
               <sqf:title>Insert today's date and time (ISO)</sqf:title>
            </sqf:description>
            <sqf:replace match="." target="when-iso" node-type="attribute">
               <value-of select="current-dateTime()"/>
            </sqf:replace>
         </sqf:fix>
      </rule>
      <rule context="tei:div[not(tei:div)]//*" role="warning">
         <report test="@xml:lang" sqf:fix="remove-xmllang">Language differentiations below leaf div
            level may be ignored in alignments.</report>
         <sqf:fix id="remove-xmllang">
            <sqf:description>
               <sqf:title>Remove @xml:lang</sqf:title>
            </sqf:description>
            <sqf:replace match="@xml:lang"/>
         </sqf:fix>
      </rule>
   </pattern>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-TEI-functions.xsl"/>

</schema>
