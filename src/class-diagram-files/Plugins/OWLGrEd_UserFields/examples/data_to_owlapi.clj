{"ontologies" [{"ontology-str" "Prefix(:=<http://lu.lv/kc/2010/7/MiniUniv.owl#>)\
Prefix(owl:=<http://www.w3.org/2002/07/owl#>)\
Prefix(rdf:=<http://www.w3.org/1999/02/22-rdf-syntax-ns#>)\
Prefix(xml:=<http://www.w3.org/XML/1998/namespace>)\
Prefix(xsd:=<http://www.w3.org/2001/XMLSchema#>)\
Prefix(rdfs:=<http://www.w3.org/2000/01/rdf-schema#>)\
Prefix(owl2xml:=<http://www.w3.org/2006/12/owl2-xml#>)\
Prefix(MiniUniv:=<http://lu.lv/kc/2010/7/MiniUniv.owl#>)\
\
\
Ontology(<http://lu.lv/kc/2010/7/MiniUniv.owl>\
\
Declaration(Class(:Academic_Program))\
Declaration(Class(:Assistant))\
SubClassOf(:Assistant :Teacher)\
Declaration(Class(:Associate_Professor))\
SubClassOf(:Associate_Professor :Teacher)\
Declaration(Class(:Course))\
SubClassOf(:Course ObjectUnionOf(:Optional_Course :Mandatory_Course))\
Declaration(Class(:Mandatory_Course))\
SubClassOf(:Mandatory_Course :Course)\
SubClassOf(:Mandatory_Course ObjectAllValuesFrom(:isTaughtBy :Professor))\
DisjointClasses(:Mandatory_Course :Optional_Course)\
Declaration(Class(:Optional_Course))\
SubClassOf(:Optional_Course :Course)\
DisjointClasses(:Optional_Course :Mandatory_Course)\
Declaration(Class(:Person))\
Declaration(Class(:Person_ID))\
SubClassOf(:Person_ID ObjectMaxCardinality(1 :person :Person))\
Declaration(Class(:Professor))\
SubClassOf(:Professor :Teacher)\
Declaration(Class(:Student))\
SubClassOf(:Student :Person)\
Declaration(Class(:Teacher))\
SubClassOf(:Teacher :Person)\
SubClassOf(:Teacher ObjectUnionOf(:Assistant :Associate_Professor :Professor))\
Declaration(ObjectProperty(:belongsTo))\
InverseObjectProperties(:includes :belongsTo)\
ObjectPropertyDomain(:belongsTo :Course)\
ObjectPropertyRange(:belongsTo :Academic_Program)\
Declaration(ObjectProperty(:enrolled))\
ObjectPropertyDomain(:enrolled :Student)\
ObjectPropertyRange(:enrolled :Academic_Program)\
Declaration(ObjectProperty(:includes))\
InverseObjectProperties(:includes :belongsTo)\
ObjectPropertyDomain(:includes :Academic_Program)\
ObjectPropertyRange(:includes :Course)\
Declaration(ObjectProperty(:isTakenBy))\
InverseObjectProperties(:takes :isTakenBy)\
ObjectPropertyDomain(:isTakenBy :Course)\
ObjectPropertyRange(:isTakenBy :Student)\
Declaration(ObjectProperty(:isTaughtBy))\
InverseObjectProperties(:teaches :isTaughtBy)\
ObjectPropertyDomain(:isTaughtBy :Course)\
ObjectPropertyRange(:isTaughtBy :Teacher)\
Declaration(ObjectProperty(:person))\
InverseObjectProperties(:person :personID)\
ObjectPropertyDomain(:person :Person_ID)\
ObjectPropertyRange(:person :Person)\
Declaration(ObjectProperty(:personID))\
InverseObjectProperties(:person :personID)\
ObjectPropertyDomain(:personID :Person)\
ObjectPropertyRange(:personID :Person_ID)\
Declaration(ObjectProperty(:takes))\
InverseObjectProperties(:takes :isTakenBy)\
ObjectPropertyDomain(:takes :Student)\
ObjectPropertyRange(:takes :Course)\
DisjointObjectProperties(:takes :teaches)\
Declaration(ObjectProperty(:teaches))\
InverseObjectProperties(:teaches :isTaughtBy)\
ObjectPropertyDomain(:teaches :Teacher)\
ObjectPropertyRange(:teaches :Course)\
DisjointObjectProperties(:teaches :takes)\
Declaration(DataProperty(:IDValue))\
DataPropertyDomain(:IDValue :Person_ID)\
DataPropertyRange(:IDValue xsd:string)\
Declaration(DataProperty(:courseName))\
DataPropertyDomain(:courseName :Course)\
DataPropertyRange(:courseName xsd:string)\
Declaration(DataProperty(:personName))\
DataPropertyDomain(:personName :Person)\
DataPropertyRange(:personName xsd:string)\
Declaration(DataProperty(:programName))\
DataPropertyDomain(:programName :Academic_Program)\
DataPropertyRange(:programName xsd:string)\
DisjointClasses(:Assistant :Associate_Professor :Professor)\
DisjointClasses(:Academic_Program :Course :Person :Person_ID)\
)" "ontology-iri" "http://lu.lv/kc/2010/7/MiniUniv.owl"}] "active_ontology_iri" "http://lu.lv/kc/2010/7/MiniUniv.owl" "custom_render_spec" {"axioms" "\
AnnotationAssertion(\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_RequireValue> \"true\")\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_CreateValue> \"true\")\
<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForRole_ShowAnnotation_InField>\
<http://lumii.lv/ontologies/example.owl#isComposition>\
\"isComposition\")\
AnnotationAssertion(\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_RequireValue> \"true\")\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_CreateValue> \"true\")\
<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForRole_ShowAnnotation_InField>\
<http://lumii.lv/ontologies/example.owl#isComposition>\
\"isComposition\")\
AnnotationAssertion(\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_RequireValue> \"true\")\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_CreateValue> \"true\")\
<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForRole_ShowAnnotation_InField>\
<http://lumii.lv/ontologies/example.owl#isDerivedUnion>\
\"isDerivedUnion\")\
AnnotationAssertion(\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_RequireValue> \"true\")\
Annotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_CreateValue> \"true\")\
<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForRole_ShowAnnotation_InField>\
<http://lumii.lv/ontologies/example.owl#isDerivedUnion>\
\"isDerivedUnion\")" "prefixes" "Prefix(owlFields:=<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#>)\
Prefix(example:=<http://lumii.lv/ontologies/example.owl#>)"}}