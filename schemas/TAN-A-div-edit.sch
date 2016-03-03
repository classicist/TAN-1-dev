<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron tests for TAN-A-div files. Lightweight version, pointing only to those
      components that are needed to interrogate sources, without performing tokenization
      tests.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>
   
   <include href="TAN-core.sch"/>
   <!--<xsl:include href="../functions/TAN-core-functions.xsl"/>-->
   <include href="TAN-class-2.sch"/>
   <xsl:include href="../functions/TAN-class-2-functions.xsl"/>
   <include href="TAN-A-div-lite.sch"/>
   <!--<xsl:include href="../functions/TAN-A-div-edit-functions.xsl"/>-->
</schema>
