<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <!-- Generates a catalog file for schema/ and functions/; important for functions, where catalog files 
        are used in lieu of bare fn:collection() so that validation files can be housed on an apache server -->
    <xsl:output indent="yes"/>
    <xsl:variable name="function-URIs">
        <collection stable="true">
            <xsl:for-each select="collection('.?select=*.x[ms]l')">
                <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','$1')}"/>
            </xsl:for-each>
        </collection>
    </xsl:variable>
    <xsl:variable name="schema-URIs">
        <collection stable="true">
            <xsl:for-each
                select="
                    collection('../schemas?select=*.sch;recurse=yes'),
                    collection('../schemas?select=*.rng;recurse=yes')">
                <doc href="{replace(base-uri(.),'.+[/\\]([^/\\]+)$','$1')}"/>
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