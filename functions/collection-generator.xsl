<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <!-- Input: any file -->
    <!-- Output: a catalog file for schemas/, functions/, and TAN-key -->
    <!-- The resultant files are important for the function library and validation, which can use fn:collection() only in connection with an XML file listing the XML files available. -->
    <xsl:output indent="yes"/>
    <xsl:variable name="function-URIs">
        <collection stable="true">
            <xsl:for-each select="collection('.?select=*.x[ms]l')">
                <xsl:if test="not(base-uri(.) = static-base-uri())">
                    <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','$1')}"/>
                </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="collection('incl/.?select=*.x[ms]l')">
                <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','incl/$1')}"/>
            </xsl:for-each>
            <xsl:for-each select="collection('errors/.?select=*.x[ms]l')">
                <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','errors/$1')}"/>
            </xsl:for-each>
        </collection>
    </xsl:variable>
    <xsl:variable name="schema-URIs">
        <collection stable="true">
            <xsl:for-each
                select="
                    collection('../schemas?select=*.sch'),
                    collection('../schemas?select=*.rng')">
                <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','$1')}"/>
            </xsl:for-each>
            <xsl:for-each
                select="
                collection('../schemas/incl?select=*.sch'),
                collection('../schemas/incl?select=*.rng')">
                <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','incl/$1')}"/>
            </xsl:for-each>
        </collection>
    </xsl:variable>
    <xsl:variable name="key-URIs">
        <collection stable="true">
            <xsl:for-each select="
                    collection('../TAN-key?select=*.xml')">
                <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','$1')}"/>
            </xsl:for-each>
        </collection>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:result-document href="{resolve-uri('collection.xml',static-base-uri())}">
            <xsl:copy-of select="$function-URIs"/>
        </xsl:result-document>
        <xsl:result-document href="{resolve-uri('../schemas/collection.xml',static-base-uri())}">
            <xsl:copy-of select="$schema-URIs"/>
        </xsl:result-document>
        <xsl:result-document href="{resolve-uri('../TAN-key/collection.xml',static-base-uri())}">
            <xsl:copy-of select="$key-URIs"/>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>