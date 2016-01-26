<?xml version="1.0" encoding="UTF-8"?>
<!-- To do: 
   ADD rule to <tokenization>: for any tokenization not already recommended by 
   a source, ensure that tokenization on the source text is identical no matter how modifying letters are handled (probably time consuming)
   Ensure that <rename-div-ns> does not break the LDUR; document for guidelines
   Ensure that tan:tok/@cont is used to fuse tokens.
-->

<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron tests for class 2 TAN files.</title>

   <rule context="tan:source">
      <let name="self-resolved" value="tan:resolve-include(.)"/>
      <let name="this-pos" value="count(preceding-sibling::tan:source) + 1"/>
      <let name="all-leafdiv-flatrefs" value="$src-1st-da-data[$this-pos]/tan:div[@lang]/@ref"/>
      <let name="exists-new-version"
         value="$src-1st-da-heads[$this-pos]/tan:see-also[tan:relationship = 'new version']"/>
      <let name="duplicate-leafdiv-flatrefs"
         value="$all-leafdiv-flatrefs[index-of($all-leafdiv-flatrefs,.)[2]]"/>
      <assert
         test="every $i in $self-resolved
               satisfies exists(tan:first-loc-available($i))"
         role="fatal">At least one copy of each source must be available to validate file.</assert>
      <report test="exists($duplicate-leafdiv-flatrefs)">After declarations are applied, source must
         preserve the Leaf Div Uniqueness Rule (broken at <value-of
            select="string-join($duplicate-leafdiv-flatrefs, ', ')"/>).</report>
      <report test="$exists-new-version" role="warning" sqf:fix="use-new-edition"><!-- Upon validation, if a source is found to have a <see-also> that has a <relationship> of 'new-version', a warning will be returned indicating that an updated version is available -->New version
         exists. IRI: <value-of select="$exists-new-version/tan:IRI"/> Name: <value-of
            select="$exists-new-version/tan:name"/>
         <value-of select="$exists-new-version/tan:desc"/> Location: <value-of
            select="$exists-new-version/tan:location/@href"/></report>
      <sqf:fix id="use-new-edition">
         <sqf:description>
            <sqf:title>Replace with new version</sqf:title>
            <sqf:p>If the source is found to have a see-also that has a relationship of 'new-version', choosing this option will replace the IRI + name pattern with the one in the source file's see-also.</sqf:p>
         </sqf:description>
         <sqf:delete match="child::*"/>
         <sqf:add match="."
            select="$exists-new-version/* except $exists-new-version/tan:relationship"/>
      </sqf:fix>
   </rule>
   <rule context="tan:tokenization">
      <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
      <let name="pos-per-src"
         value="for $i in $this-src-list return count(preceding-sibling::tan:tokenization[$i = tan:src-ids-to-nos(@src)]) + 1"/>
      <let name="this-tokz-per-src"
         value="for $i in $this-src-list return $tokenizations-per-source[$i]/tan:tokenization[$pos-per-src[index-of($this-src-list,$i)]]"
      />
      <let name="these-tokz-errors"
         value="for $i in (1 to count($this-tokz-per-src)), $j in $this-tokz-per-src[$i] return 
         if ($j/tan:location[(@href,@error) = $tokenization-errors]) then concat($src-ids[$this-src-list[$i]],': ',$j/tan:location/@href) else ()"
      />
      <report test="$these-tokz-errors"><!-- Common errors in <tokenization>: $tokenization-errors -->Error: <value-of select="$these-tokz-errors"/>
      </report>
   </rule>
   <rule context="tan:suppress-div-types|tan:div-type-ref|tan:rename-div-ns">
      <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
      <let name="this-div-types" value="tokenize(@div-type-ref,'\s+')"/>
      <let name="src-div-type-mismatch"
         value="for $i in $this-src-list, $j in $this-div-types, $k in ($rename-div-types/tan:source[$i]/tan:rename[@new = $j]/@old,$j)[1] 
         return
         if($src-1st-da-heads[$i]/tan:declarations/tan:div-type[@xml:id = $k])
         then ()
         else concat($src-ids[$i],':',$j)"/>
      <let name="src-div-type-uses-old"
         value="for $i in $this-src-list, $j in $this-div-types, $k in $rename-div-types/tan:source[$i]/tan:rename[@old = $j]
         return concat($src-ids[$i],':',$j)"/>
      <report test="count($src-div-type-mismatch) gt 0">Every div type value must valid in every source (<value-of
            select="for $i in $this-src-list,
            $j in $src-1st-da-all-div-types/tan:source[$i]//@xml:id return ($rename-div-types/tan:source[$i]/tan:rename[@old = $j]/@new,$j)[1]"
         />).</report>
      <report test="exists($src-div-type-uses-old)">May not refer to a div type with a name that has been changed elsewhere
            (<value-of select="$src-div-type-uses-old"/>).</report>
   </rule>
   <rule context="tan:implicit-div-type-refs">
      <let name="this-src-list" value="$src-impl-div-types"/>
      <let name="empty-ns"
         value="for $i in $src-impl-div-types-not-already-recommended return
         if (some $j in $src-1st-da-data[$i]//@ref satisfies 
         matches($j,concat($separator-type-and-n-regex,'$|',$separator-hierarchy-regex,$separator-type-and-n-regex))) then $i else ()"/>
      <report test="exists($empty-ns)">Implicitation not allowed for sources with empty values for
         @n (<value-of select="for $i in $empty-ns return $src-ids[$i]"/>).</report>
      <report test="exists($duplicate-implicit-refs)">Implicitation not allowed for sources where
         ignoring types would result in duplicate flattened references to leaf divs, a violation of
         the Leaf Div Uniqueness Rule (<value-of select="string-join($duplicate-implicit-refs,'; ')"
         />).</report>
   </rule>
   <rule context="tan:rename-div-types">
      <report role="warning" test="@src = tokenize(../tan:implicit-div-type-refs/@src,'\s+')"
         >Renaming div types for a source where div type references are declared to be implicit has
         no effect.</report>
   </rule>
   <rule context="tan:rename[parent::tan:rename-div-types]">
      <let name="this-src-list" value="tan:src-ids-to-nos(../@src)"/>
      <let name="this-div-type" value="@old"/>
      <assert
         test="every $i in $this-src-list satisfies $src-1st-da-heads[$i]//tan:div-type[@xml:id=$this-div-type]"
         >For rename-div-types, every div type must be found in every source.</assert>
   </rule>
   <rule context="tan:rename[parent::tan:rename-div-ns]">
      <let name="this-src-list" value="tan:src-ids-to-nos(../@src)"/>
      <let name="this-div-type-list" value="tokenize(../@div-type-ref,'\s+')"/>
      <let name="this-div-type-list-orig"
         value="for $i in $this-src-list return string-join(for $j in $this-div-type-list return 
         ($head/tan:declarations/tan:rename-div-types[tan:src-ids-to-nos(@src) = $i]/tan:rename[@new = $j]/@old,$j)[1],' ')"/>
      <let name="this-div-type-list-orig-as-regex"
         value="for $i in $this-div-type-list-orig return concat('(',replace($i,' ','|'),')')"/>
      <let name="this-div-n" value="@old"/>
      <let name="this-div-type-ord-check"
         value="for $i in (1 to count($this-src-list)) return 
         $div-type-ord-check/tan:source[position() = $this-src-list[$i]]/tan:div-type[@id = tokenize($this-div-type-list-orig[$i],' ')]"/>
      <let name="ns-are-type-i"
         value="every $i in $this-div-type-ord-check satisfies $i/@type = 'i'"/>
      <let name="ns-are-type-a"
         value="every $i in $this-div-type-ord-check satisfies $i/@type = 'a'"/>
      <let name="ns-are-what-type"
         value="for $i in $this-div-type-ord-check/@type return $n-type-label[index-of($n-type,$i)]"/>
      <assert
         test="if (matches($this-div-n,'#')) then true() else
         every $i in (1 to count($this-src-list)) satisfies $src-1st-da-data[$this-src-list[$i]]//tan:div[matches(@old-ref,concat(
         $this-div-type-list-orig-as-regex[$i],
         $separator-type-and-n-regex,
         $this-div-n,
         $separator-hierarchy-regex,
         '|',$this-div-type-list-orig-as-regex[$i],
         $separator-type-and-n-regex,
         $this-div-n,
         '$'))]"
         >For rename-div-ns, every n value must be found in at least one div type in every source.</assert>
      <assert test="matches(@old,'#') = matches(@new,'#')">For rename-div-ns, if a numeration system
         is to be renamed, the appropriate rename element must have the valid pattern identifiers in @old and @new for letter, Roman, or Arabic numerals -- #a, #i, or #1 respectively</assert>
      <report test="@old = @new">@old and @new may not take the same value</report>
      <assert test="if (@old = '#a') then ($ns-are-type-a) else true()">If converting @n numeration
         from letter numerals to Arabic, the @n values for each div type of each source must be
         predominantly letter numerals (currently <value-of
            select="string-join($ns-are-what-type,', ')"/>)</assert>
      <assert test="if (@old = '#i') then ($ns-are-type-a) else true()">If converting @n numeration
         from roman numerals to Arabic, the @n values for each div type of each source must be
         predominantly Roman numerals (currently <value-of
            select="string-join($ns-are-what-type,', ')"/>)</assert>
   </rule>
   <rule context="@ref">
      <let name="these-refs" value="normalize-space(.)"/>
      <let name="this-src-list" value="if (../@src) then tan:src-ids-to-nos(../@src) else 1"/>
      <let name="this-refs-norm"
         value="for $i in $this-src-list
         return
         if ($i = $src-impl-div-types) then
         tan:normalize-impl-refs(., $i)
         else
         tan:normalize-refs(.)"
      />
      <let name="possible-divs" value="for $i in $this-src-list, $j in $this-refs-norm, $k in tokenize($j,' [-,] ')
          return $src-1st-da-data[$i]/tan:div[starts-with(@ref,$j)]"/>
      <let name="possible-refs" value="if ($this-src-list = $src-impl-div-types) then $possible-divs/@impl-ref
         else $possible-divs/@ref"/>
      <let name="ref-range-must-join-siblings"
         value="if (../parent::tan:realign or ../..[@distribute] or ../..[@xml:id]) then true() else false()"/>
      <report
         test="$ref-range-must-join-siblings and (some $i in tan:ref-range-check(.) satisfies $i = false())"
         >In any @ref whose values might be distributed, every range (references joined by a hyphen)
         must begin and end with siblings.</report>
      <report test="matches(.,'\?')" role="info"><!-- If you add a question mark to a partially completed reference, you will get in response a list of all possible valid references -->Help: <value-of select="$possible-refs"/></report>
   </rule>
   <rule context="tan:tok">
      <let name="src-data-for-this-tok" value="tan:pick-tokenized-prepped-class-1-data(.)"/>
      <let name="help-requested" value="tan:help-requested(.)"/>
      <let name="val-without-help" value="normalize-space(replace(@val,'\s+\?|\?\s+',''))"/>
      <let name="token-ceiling"
         value="min(for $i in $src-data-for-this-tok/tan:div return if($val-without-help) 
         then count($i/tan:tok[matches(.,$val-without-help)]) else number($i/@max-toks))"/>
      <let name="char-ceiling"
         value="min(for $i in $src-data-for-this-tok//tan:tok return string-length($i))"/>
      <let name="this-chars"
         value="if (@chars) then normalize-space(replace(@chars,'\?','')) else ()"/>
      <let name="this-char-max"
         value="if (exists($this-chars)) then tan:max-integer($this-chars) else 1"/>
      <let name="this-char-min-last"
         value="if (exists($this-chars) and exists($char-ceiling)) then tan:min-last($this-chars,$char-ceiling) else 1"/>
      <let name="this-src-qty-with-implicit-div-types"
         value="count($src-data-for-this-tok[position() = $src-impl-div-types][tan:div])"/>
      <let name="src-data-for-sibling-toks"
         value="for $i in (preceding-sibling::tan:tok, following-sibling::tan:tok)[not(tan:help-requested(.))] 
         return tan:pick-tokenized-prepped-class-1-data($i)"/>
      <let name="duplicate-tokens"
         value="for $i in $src-data-for-this-tok//tan:tok, 
         $j in $src-data-for-sibling-toks//tan:tok return
         if (deep-equal($i,$j)) then 
         if ($i/../@ref = $j/../@ref and $i/../../@id = $j/../../@id) then true() else () 
         else ()"/>
      <report test="exists($duplicate-tokens) and not($help-requested)">May not point to the same
         token that a sibling tok element does.</report>
      <report test="some $i in $src-data-for-this-tok/tan:div satisfies $i = $tokenization-errors"
         tan:does-not-apply-to="tok">Tokenization error (<value-of
            select="for $i in $src-data-for-this-tok/tan:div[. = $tokenization-errors] return concat($i/@ref,': ',$i/@lang)"
         />)</report>
      <report test="not(@pos or @val)">Must point to a string value via @val, a sequence via @pos, or
         both.</report>
      <report test="$src-data-for-this-tok/tan:div/@error">Every value of @ref must be found in
         every source (<value-of
            select="for $i in $src-data-for-this-tok/tan:div[@error] return concat($i/../@id,': ',$i/@ref)"
         />).</report>
      <report test="$src-data-for-this-tok/tan:div/tan:tok[@error]">Every token picked must appear
         in every ref in every source<value-of
            select="if (tokenize(@val,'\s+') = 'last') then ' (&quot;last&quot; 
            usually goes with the attribute @pos, not @val)' else ()"
         /> (errors: <value-of
            select="for $i in $src-data-for-this-tok/tan:div[tan:tok[@error]] return 
            concat($i/../@id,': ',$i/@ref,' tok ',string-join($i/tan:tok/@error,' '))"
         />) <value-of select="$src-data-for-this-tok//(@error, @test)"/></report>
      <report
         test="if (exists($this-chars)) then ($this-char-max gt $char-ceiling) or ($this-char-min-last lt 1) 
         else false()" tan:applies-to="char"
         >If @chars is used, every character must appear in every token in every ref in every source (tokens
         chosen have <value-of select="$char-ceiling"/> characters max)</report>
      <report test="$src-data-for-this-tok/tan:div[not(@lang)]">@ref must refer to a leaf div in
         every source (<value-of
            select="string-join(for $i in $src-data-for-this-tok/tan:div[not(@lang)] return concat($i/../@id,':',$i/@ref),', ')"
         />)</report>
      <report test="matches(@pos,'\?')" role="info" tan:applies-to="ord">
         <!-- If you insert a question mark anywhere as the value of @pos and then validate the file, you will be given a list of allowed values. -->
         Help: acceptable values 1 through <value-of
            select="$token-ceiling"/></report>
      <report test="matches(@chars,'\?')" role="info" tan:applies-to="chars">
         <!-- If you insert a question mark anywhere as the value of @chars and then validate the file, you will be given a list of allowed values. -->
         Help: acceptable values 1 through <value-of
            select="$char-ceiling"/></report>
      <report
         test="
            @chars and (some $i in $src-data-for-this-tok/tan:div/tan:tok
               satisfies matches($i, '\p{M}'))"
         tan:applies-to="chars" role="warning">Any @chars applied to a token that has combining
         characters will identify only base characters, grouped with any immediately following
         combining characters.</report>
      <report
         test="$this-src-qty-with-implicit-div-types gt 0 and 
         $this-src-qty-with-implicit-div-types ne count(tan:src-ids-to-nos(@src))"
         >Sources that take implicit div type references may not be mixed with those that take explicit ones. (<value-of select="$this-src-qty-with-implicit-div-types"/>,
            <value-of select="count(tan:src-ids-to-nos(@src))"/>)</report>
      <report
         test="$src-data-for-this-tok//tan:tok[@n = '1'][not(@error)] and parent::tan:split-leaf-div-at and
            not($help-requested)"
         >May not be used to split a leaf div at the first token.</report>
      <report test="@val and $help-requested" role="info" tan:applies-to="val">
         <!-- If you insert a question mark anywhere as the value of @val and then validate the file, you will be given a list of allowed values. -->
         Help: 
         <value-of
            select="for $i in $src-data-for-this-tok,
                  $j in $i/tan:div
               return
                  string-join(concat($j/@ref, ': ', string-join(for $k in distinct-values($j/tan:tok)
                  return
                     concat($k, '[', count($j/tan:tok[. = $k]), ']'), ', ')), '; ')"
         /></report>
      <report test="@cont and count($src-data-for-this-tok//tan:tok) gt 1">Any &lt;tok>
      that is continued via @cont must point to only a single token.</report>
      <report
         test="preceding-sibling::tan:tok[1]/@cont and count($src-data-for-this-tok//tan:tok) gt 1"
         >Any &lt;tok> that continues a previous one (via @cont) must point to only a single
         token.</report>
      <report test="@cont and not(following-sibling::tan:tok)" tan:applies-to="cont">Any &lt;tok> taking 
         @cont must be followed by at least one other &lt;tok>.</report>
   </rule>
   <rule context="@strength|@conf">
      <let name="pos" value="count(../preceding-sibling::*[not(@cont)])"/>
      <let name="joined-siblings" value="../../(tan:div-ref,tan:tok)[count(preceding-sibling::*[not(@cont)]) = $pos]"/>
      <!-- START TESTING BLOCK -->
      <let name="test1" value="$pos"/>
      <let name="test2" value="$joined-siblings"/>
      <let name="test3" value="count($joined-siblings//(@strength | @conf))"/>
      <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
         select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
      <!-- END TESTING BLOCK -->
      <report test="count($joined-siblings//(@strength | @conf)) gt 1">Neither @strength nor @conf
         may be repeated by siblings joined by @cont.</report>
   </rule>
</pattern>
