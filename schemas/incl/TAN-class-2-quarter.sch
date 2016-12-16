<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" id="class-2-quarter">
   <title>Schematron tests for class 2 TAN files, second level of expansion.</title>
   <!-- variables as document-node() -->
   <!--<let name="srcs-1st-da" value="tan:get-src-1st-da()"/>
   <let name="srcs-resolved" value="tan:get-src-1st-da-resolved($srcs-1st-da, $src-ids)"/>
   <let name="self-expanded-2"
      value="tan:get-self-expanded-2($self-prepped[1], $srcs-resolved)"/>
   <!-\- derived global variables -\->
   <let name="new-src-versions"
      value="$srcs-resolved/*/tan:head/tan:see-also[tan:relationship/tan:IRI = $TAN-keywords//tan:item[tan:name = 'update']/tan:IRI]"/>
   <let name="n-types" value="tan:get-n-types($srcs-resolved)"/>
   <let name="self2-errors" value="$self-expanded-2//*[tan:error]"/>-->
   
   <!--<rule context="tan:declarations">
      <report test="not($head/tan:declarations/tan:class-type) and $body//@class">@class may be invoked
         only if it is defined by &lt;class-type>.
      </report>
   </rule>-->
   <!--<rule context="tan:source">
      <let name="this-resolved" value="$empty-doc"/>
      <let name="new-versions" value="$new-src-versions[root()/*/@src = $this-resolved/@xml:id]"/>
      <report test="exists($new-versions)" role="warning"
         ><!-\- Upon validation, if a source is found to have a <see-also> that has a <relationship> of 'new-version', a warning will be returned indicating that an updated version is available -\->This
         source has an update available (<value-of select="$new-versions//@href"/>)</report>
   </rule>-->
   <!--<rule context="tan:suppress-div-types | tan:div-type-ref | tan:rename-div-ns">
      <let name="this-resolved" value="$empty-doc"/>
      <let name="this-expanded" value="tan:expand-src-and-div-type-ref($this-resolved/*)"/>
      <let name="src-div-type-mismatches"
         value="
            for $i in $this-expanded
            return
               if ($srcs-resolved/*[@src = $i/@src]/tan:head/tan:declarations/tan:div-type[@xml:id = $i/@div-type-ref])
               then
                  ()
               else
                  $i"/>
      <let name="old-ns-not-found"
         value="
            for $i in $this-expanded,
               $j in $i/tan:rename[not(@old = ('#i', '#a'))]
            return
               if ($n-types[@src = $i/@src]/tan:div-type[@xml:id = $i/@div-type-ref][tokenize(@unique-n-values, ' ') = $j/@old]) then
                  ()
               else
                  $j"/>
      <let name="duplicated-renames" value="$this-resolved/tan:rename[@old = @new]"/>
      <let name="mismatched-n-types"
         value="
            $this-resolved/tan:rename[(matches(@old, '#') and not(matches(@new, '#'))) or
            (matches(@new, '#') and not(matches(@old, '#')))]"/>
      <let name="attempts-to-rename-type-a" value="$this-expanded[tan:rename/@old = '#a']"/>
      <let name="erroneous-attempts-to-rename-type-a"
         value="
            for $i in $attempts-to-rename-type-a,
               $j in $n-types[@src = $i/@src]/tan:div-type[@xml:id = $i/@div-type-ref]
            return
               if ($j[not(@n-type = 'a')])
               then
                  ($i, $j)
               else
                  ()"/>
      <let name="attempts-to-rename-type-i" value="$this-expanded[tan:rename/@old = '#i']"/>
      <let name="erroneous-attempts-to-rename-type-i"
         value="
            for $i in $attempts-to-rename-type-i,
               $j in $n-types[@src = $i/@src]/tan:div-type[@xml:id = $i/@div-type-ref]
            return
               if ($j[not(@n-type = 'i')])
               then
                  ($i, $j)
               else
                  ()"/>
      <!-\-<report test="exists($src-div-type-mismatches)">Every div type value must be valid in every
         source (<value-of select="$src-div-type-mismatches/@*"/>).</report>-\->
      <!-\-<report test="exists($duplicated-renames)" tan:applies-to="old new"
         tan:does-not-apply-to="suppress-div-types div-type-ref">@old and @new may not take the same
         value ( <value-of select="$duplicated-renames/@*"/>)</report>-\->
      <!-\-<report test="exists($old-ns-not-found)" tan:applies-to="old rename"
         tan:does-not-apply-to="suppress-div-types div-type-ref">Every @old must be found for every
         @div-type-ref for every @src ( <value-of
            select="
               for $i in $old-ns-not-found
               return
                  concat($i/../@src, ':', $i/../@div-type-ref, ':', $i/@old)"
         />)</report>-\->
      <!-\-<report test="exists($mismatched-n-types)" tan:applies-to="old new rename" tan:does-not-apply-to="suppress-div-types div-type-ref">If @new or @old refers to an n type (#1, #a, #i)
         then the other must as well.</report>-\->
      <!-\-<report test="exists($erroneous-attempts-to-rename-type-a)" tan:applies-to="old new rename" tan:does-not-apply-to="suppress-div-types div-type-ref">@n numeration conversion from
         letter numerals to Arabic must be applied to @n values that are predominantly letter
         numerals (currently <value-of
            select="
               for $i in (1 to (count($erroneous-attempts-to-rename-type-a) idiv 2)),
                  $j in $erroneous-attempts-to-rename-type-a[($i * 2) - 1],
                  $k in $erroneous-attempts-to-rename-type-a[($i * 2)]
               return
                  concat($j/@src, ':', $j/@div-type-ref, ' is predominantly ',
                  $k/@n-type)"
         />)</report>-\->
      <!-\-<report test="exists($erroneous-attempts-to-rename-type-i)" tan:applies-to="old new rename"
         tan:does-not-apply-to="suppress-div-types div-type-ref">@n numeration conversion from
         Roman numerals to Arabic must be applied to @n values that are predominantly Roman numerals
         (currently <value-of
            select="
               for $i in (1 to (count($erroneous-attempts-to-rename-type-i) idiv 2)),
                  $j in $erroneous-attempts-to-rename-type-i[($i * 2) - 1],
                  $k in $erroneous-attempts-to-rename-type-i[($i * 2)]
               return
                  concat($j/@src, ':', $j/@div-type-ref, ' is predominantly ',
                  $k/@n-type)"
         />)</report>-\->
   </rule>-->
   <!--<rule context="*">
      <let name="this-element-name" value="name(.)"/>
      <let name="this-q" value="count(preceding-sibling::*[name() = $this-element-name]) + 1"/>
      <let name="errors" value="$self2-errors[name(.) = $this-element-name][@q = $this-q]/tan:error"/>
      <!-\-<report test="exists(@cont )and not(following-sibling::*[name(.) = $this-element-name])">Any element taking
         @cont must be followed by at least one sibling of the same type.</report>-\->
      <!-\-<report test="exists(@cont )and following-sibling::*[1][@cert or @strength]">No element may be continued by one
         that takes either @cert or @strength. </report>-\->
      <!-\-<report test="exists($errors)">ERROR: <value-of select="$errors"/></report>-\->
   </rule>-->

</pattern>