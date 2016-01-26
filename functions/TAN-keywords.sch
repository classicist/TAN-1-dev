<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tan="tag:textalign.net,2015:ns">
    <sch:title>Tests for TAN-A-tok files.</sch:title>
    <sch:ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
    <sch:ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
    <sch:ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>

    <sch:let name="all-IRIs" value="//tan:IRI"/>
    <sch:let name="duplicate-IRIs" value="$all-IRIs[index-of($all-IRIs, .)[2]]"/>
    <sch:let name="all-keywords" value="//tan:keyword"/>
    <sch:let name="duplicate-keywords" value="$all-keywords[index-of($all-keywords, .)[2]]"/>
    <sch:let name="TAN-namespace" value="'tag:textalign.net,2015'"/>
    <sch:pattern>
        <sch:rule context="tan:IRI">
            <sch:report test="not(@see) and (. = $duplicate-IRIs)">Duplicate IRIs not
                allowed</sch:report>
        </sch:rule>
        <sch:rule context="tan:keyword">
            <sch:report test="not(@see) and (. = $duplicate-keywords)">Duplicate keywords not
                allowed</sch:report>
        </sch:rule>
        <sch:rule context="tan:item">
            <sch:assert
                test="
                    tan:IRI/@see or
                    (some $i in tan:IRI/text()
                        satisfies starts-with($i, $TAN-namespace))"
                sqf:fix="add-TAN-IRI">Items require TAN IRIs</sch:assert>
            <sqf:fix id="add-TAN-IRI">
                <sqf:description>
                    <sqf:title>Add TAN IRI</sqf:title>
                </sqf:description>
                <sqf:add position="before" match="(tan:IRI[1],tan:desc[1],*[1])[1]">
                    <tan:IRI><xsl:value-of select="concat($TAN-namespace,':div-type:',replace(../tan:keyword[1],'\s+','_'))"></xsl:value-of></tan:IRI>
                    <xsl:value-of select="'&#xA;'"></xsl:value-of>
                </sqf:add>
            </sqf:fix>
        </sch:rule>
    </sch:pattern>
</sch:schema>
