<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
   <title>Tests for TAN-TEI files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <include href="incl/TAN-core.sch"/>
   <pattern id="self-prepped" is-a="tan-file-resolved">
      <param name="self-version" value="$self-class-1-errors-marked"/>
   </pattern>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-TEI-functions.xsl"/>

</schema>
