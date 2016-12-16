<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   fpi="tag:textalign.net,2015:schema:TAN-A-div.sch">
   <title>Schematron tests for TAN-A-div files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>
   <include href="incl/TAN-core.sch"/>
   <phase id="basic">
      <active pattern="self-prepped"/>
   </phase>
   <phase id="verbose">
      <active pattern="self-analyzed"/>
   </phase>
   <pattern id="self-prepped" is-a="tan-file-resolved">
      <param name="self-version" value="$self-prepped"/>
   </pattern>
   <pattern id="self-analyzed" is-a="tan-file-resolved">
      <param name="self-version" value="tan:prep-verbosely($self-prepped, $sources-prepped)"/>
   </pattern>
   
   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-div-functions.xsl"/>
</schema>
