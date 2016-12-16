<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-LM files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>
   <include href="incl/TAN-core.sch"/>
   <pattern id="self-prepped" is-a="tan-file-resolved">
      <param name="self-version" value="$self-prepped"/>
   </pattern>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-LM-functions.xsl"/>
</schema>
