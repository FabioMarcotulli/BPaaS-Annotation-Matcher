<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text" />
	<xsl:param name="modelSetVersion">
		CloudSocketData
	</xsl:param>

	<xsl:template match="/">
		<xsl:text>
# baseURI: http://cloudsocket.eu/data
# imports: http://ikm-group.ch/archimeo/bpaas
# prefix: data

@prefix apqc: &lt;http://ikm-group.ch/archimeo/apqc#&gt; .
@prefix archi: &lt;http://ikm-group.ch/archiMEO/archimate#&gt; .
@prefix bpaas: &lt;http://ikm-group.ch/archimeo/bpaas#&gt; .
@prefix bpmn: &lt;http://ikm-group.ch/archiMEO/BPMN#&gt; .
@prefix data: &lt;http://cloudsocket.eu/data#&gt; .
@prefix fbpdo: &lt;http://ikm-group.ch/archimeo/fbpdo#&gt; .
@prefix media-types: &lt;http://www.iana.org/assignments/media-types#&gt; .
@prefix owl: &lt;http://www.w3.org/2002/07/owl#&gt; .
@prefix rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt; .
@prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt; .
@prefix xsd: &lt;http://www.w3.org/2001/XMLSchema#&gt; .

&lt;http://cloudsocket.eu/data&gt;
  rdf:type owl:Ontology ;
  owl:imports &lt;http://ikm-group.ch/archimeo/bpaas&gt; ;
  owl:versionInfo "transformed!"^^xsd:string ;
  .
</xsl:text>
		<xsl:apply-templates
			select="//MODEL[@modeltype='Business process diagram (BPMN 2.0)']"
			mode="BPMN" />
		<xsl:apply-templates
			select="//MODEL[@modeltype='Business Process Requirements Model']"
			mode="BPRequirementsModel" />
			
		<xsl:apply-templates
			select="//MODEL[@modeltype='Workflow diagram (BPMN 2.0)']" mode="Workflow" />
		<xsl:apply-templates
			select="//MODEL[@modeltype='Workflow Descriptions Model']"
			mode="WorkflowDescriptionsModel" />
	</xsl:template>

<!-- ============== ==============  Workflow (BPMN 2.0) ============== ==============  -->
	<xsl:template match="MODEL" mode="Workflow">
data:<xsl:value-of select="@id"/>
  rdf:type bpaas:Workflow ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
<xsl:call-template name="elementPostProcessing"/>
	<xsl:apply-templates select=".//INSTANCE[@class='Task']" mode="WorkflowTask" />
	<xsl:apply-templates select=".//INSTANCE[@class='Workflow Annotation Group']" mode="WorkflowAnnotationGroup" />
	
	</xsl:template>

<!-- ============== Workflow Task ============== -->
	<xsl:template match="INSTANCE" mode="WorkflowTask">
data:<xsl:value-of select="@id"/>
  rdf:type bpaas:WorkflowTask ;
  data:isPartOfWorkflow data:<xsl:value-of select="../@id"/> ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
<xsl:call-template name="elementPostProcessing"/>
	</xsl:template>
	
<!-- ============== Workflow Annotation Group ============== -->
	<xsl:template match="INSTANCE" mode="WorkflowAnnotationGroup">
data:<xsl:value-of select="@id"/>
  rdf:type bpaas:WorkflowAnnotationGroup ;
  bpaas:hasReferencedWorkflow data:<xsl:value-of select="../@id"/> ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
  <xsl:apply-templates select="./INTERREF/IREF[@type='objectreference'][@tmodeltype='Workflow Descriptions Model']" mode="referencedWorkflowDescription"/>
<xsl:call-template name="elementPostProcessing"/>
	</xsl:template>
<xsl:template name="addReferencedWorkflowDescription">		            
<xsl:param name="targetId"/>
bpaas:hasReferencedWorkflowDescription data:<xsl:value-of select="$targetId"/> ;
</xsl:template>	 
<xsl:template match="IREF" mode="referencedWorkflowDescription">
<xsl:call-template name="addReferencedWorkflowDescription">
<xsl:with-param name="targetId" select="//MODEL[@modeltype=current()/@tmodeltype][@name=current()/@tmodelname][@name=current()/@tmodelname]/INSTANCE[@class=current()/@tclassname][@name=current()/@tobjname]/@id" />
</xsl:call-template>
</xsl:template>

<!-- ============== ==============  Workflow Descriptions Model ============== ==============  -->
	<xsl:template match="MODEL" mode="WorkflowDescriptionsModel">
	<xsl:apply-templates select=".//INSTANCE[@class='Workflow Description']" mode="WorkflowDescriptions" />
	</xsl:template>

<!-- ============== Workflow Description ============== -->
	<xsl:template match="INSTANCE" mode="WorkflowDescriptions">
data:<xsl:value-of select="@id"/>
  rdf:type bpaas:WorkflowDescription ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
  bpaas:hasAvailabilityInPercent <xsl:value-of select="./ATTRIBUTE[@name='Availability in %']"/> ;
  <xsl:if test="./ATTRIBUTE[@name='Maximum Simultaneous Service Users'] !=''">bpaas:capacityIncludesSimultaneousUsers <xsl:value-of select="./ATTRIBUTE[@name='Maximum Simultaneous Service Users']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='Max Available Data Storage per Month'] !=''">bpaas:hasDataStorage <xsl:value-of select="./ATTRIBUTE[@name='Max Available Data Storage per Month']"/> ;</xsl:if> 
  
	<xsl:call-template name="APQCAnnotation"/>
	<xsl:call-template name="ObjectAnnotation"/>
	<xsl:call-template name="ActionAnnotation"/>
<xsl:call-template name="elementPostProcessing"/>
	</xsl:template>

<!-- ============== ==============  Business Requirements Model ============== ==============  -->
	<xsl:template match="MODEL" mode="BPRequirementsModel">
	<xsl:apply-templates select=".//INSTANCE[@class='Business Process Requirement']" mode="BusinessProcessRequirement" />
	</xsl:template>

<!-- ============== Business Process Requirement ============== -->
	<xsl:template match="INSTANCE" mode="BusinessProcessRequirement">
data:<xsl:value-of select="@id"/>
  rdf:type bpaas:BusinessProcessRequirement ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
  
  <xsl:if test="./ATTRIBUTE[@name='Downtime in min/month'] !=''">bpaas:hasDowntimePerMonthInMin <xsl:value-of select="./ATTRIBUTE[@name='Downtime in min/month']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='Data Encryption Annotation'] !=''">bpaas:dataEncryptionHasLevel <xsl:value-of select="./ATTRIBUTE[@name='Data Encryption Annotation']"/> ;</xsl:if> 
  <!--  <xsl:if test="./ATTRIBUTE[@name='Historical Access to Data Storage'] !=''">bpaas:backupProvidesHistoricalAccess <xsl:value-of select="./ATTRIBUTE[@name='Historical Access to Data Storage']"/> ;</xsl:if> --> 
  <!--  <xsl:if test="./ATTRIBUTE[@name='Set Expected Frequency of Storage'] !=''">bpaas:backupManagementHasExpectedFrequencyOfStorage <xsl:value-of select="./ATTRIBUTE[@name='Set Expected Frequency of Storage']"/> ;</xsl:if> --> 
  <xsl:if test="./ATTRIBUTE[@name='Data Location Annotation'] !=''">bpaas:DataSecurityRefersToALocation <xsl:value-of select="./ATTRIBUTE[@name='Data Location Annotation']"/> ;</xsl:if>
  <!-- <xsl:value-of select="./ATTRIBUTE[@name='What would you like to upload?']"/> ; --> 
  <xsl:if test="./ATTRIBUTE[@name='Number of process execution'] !=''">bpaas:capacityIncludesNumberOfProcessExecution  <xsl:value-of select="./ATTRIBUTE[@name='Number of Process Executions']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='Number of Simultaneous Users'] !=''">bpaas:capacityIncludesSimultaneousUsers <xsl:value-of select="./ATTRIBUTE[@name='Number of Simultaneous Users']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='Response Time in min'] !=''">bpaas:responseTimeIsInMinutes  <xsl:value-of select="./ATTRIBUTE[@name='Response Time in min']"/> ;</xsl:if> 
  <!--  <xsl:value-of select="./ATTRIBUTE[@name='Help-Desk Response Time in min']"/> ; -->
  <xsl:if test="./ATTRIBUTE[@name='Payment Plan Annotation'] !=''">bpaas:businessProcessRequirementHasPaymentPlan  <xsl:value-of select="./ATTRIBUTE[@name='Payment Plan Annotation']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='Payment Type'] !=''">bpaas:paymentPlanHasPaymentType <xsl:value-of select="./ATTRIBUTE[@name='Payment Type']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='User Target'] !=''">bpaas:paymentPlanHasPaymentTarget <xsl:value-of select="./ATTRIBUTE[@name='User Target']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='What would you like to upload?'] !=''">bpaas:BPRhasMediaType <xsl:value-of select="./ATTRIBUTE[@name='What would you like to upload?']"/> ;</xsl:if> 
  <xsl:if test="./ATTRIBUTE[@name='Number of process execution'] !=''">bpaas:BPRhasNumberOfProcessExecution <xsl:value-of select="./ATTRIBUTE[@name='Number of process execution']"/> ;</xsl:if>
  <xsl:if test="./ATTRIBUTE[@name='Access Period'] !=''">bpaas:hasBackupAccessPeriod <xsl:value-of select="./ATTRIBUTE[@name='Access Period']"/> ;</xsl:if>
  <xsl:if test="./ATTRIBUTE[@name='Frequency of Backup'] !=''">bpaas:hasBackupFrequency <xsl:value-of select="./ATTRIBUTE[@name='Frequency of Backup']"/> ;</xsl:if> 	
  <xsl:if test="./ATTRIBUTE[@name='Time of Restore'] !=''">bpaas:hasBackupRestoreTime <xsl:value-of select="./ATTRIBUTE[@name='Time of Restore']"/> ;</xsl:if>	
	<xsl:call-template name="APQCAnnotation"/>
	<xsl:call-template name="ObjectAnnotation"/>
	<xsl:call-template name="ActionAnnotation"/>
  
<xsl:call-template name="elementPostProcessing"/>
	</xsl:template>
	
<!-- ============== ==============  Business process diagram (BPMN 2.0) ============== ==============  -->
	<xsl:template match="MODEL" mode="BPMN">
data:<xsl:value-of select="@id"/>
  rdf:type archi:BusinessProcess ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
<xsl:call-template name="elementPostProcessing"/>
	<xsl:apply-templates select=".//INSTANCE[@class='Task']" mode="BusinessProcessTask" />
	<xsl:apply-templates select=".//INSTANCE[@class='Sub-Process']" mode="BusinessProcessSubProcess" />
	<xsl:apply-templates select=".//INSTANCE[@class='Business Process Annotation Group']" mode="BusinessProcessAnnotationGroup" />
	</xsl:template>
	
<!-- ============== Business Process Task ============== -->
	<xsl:template match="INSTANCE" mode="BusinessProcessTask">
data:<xsl:value-of select="@id"/>
  rdf:type bpmn:Task ;
  data:isPartOfBusinessProcess data:<xsl:value-of select="../@id"/> ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
<xsl:call-template name="elementPostProcessing"/>
	</xsl:template>
	
<!-- ============== Business Process Sub-Process ============== -->
	<xsl:template match="INSTANCE" mode="BusinessProcessSubProcess">
data:<xsl:value-of select="@id"/>
  rdf:type bpmn:SubProcess ;
  data:isPartOfBusinessProcess data:<xsl:value-of select="../@id"/> ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
  <xsl:apply-templates select="./INTERREF/IREF[@type='modelreference'][@tmodeltype='Business process diagram (BPMN 2.0)']" mode="referencedSubProcess"/>
<xsl:call-template name="elementPostProcessing"/>
	</xsl:template>
<xsl:template name="addReferencedSubProcessConnection">		            
<xsl:param name="targetId"/>
bpaas:hasReferencedSubBusinessProcess data:<xsl:value-of select="$targetId"/> ;<xsl:text>&#10;</xsl:text>
</xsl:template>	 
<xsl:template match="IREF" mode="referencedSubProcess">
<xsl:call-template name="addReferencedSubProcessConnection">
<xsl:with-param name="targetId" select="//MODEL[@modeltype=current()/@tmodeltype][@name=current()/@tmodelname][@name=current()/@tmodelname][@name=current()/@tmodelname]/@id"/>
</xsl:call-template>
</xsl:template>

<!-- ============== Business Process Annotation Group ============== -->
	<xsl:template match="INSTANCE" mode="BusinessProcessAnnotationGroup">
data:<xsl:value-of select="@id"/>
  rdf:type bpaas:BusinessProcessAnnotationGroup ;
  bpaas:hasReferencedBusinessProcess data:<xsl:value-of select="../@id"/> ;
  rdfs:label "<xsl:value-of select="@name"/>"^^xsd:string ;
  <xsl:apply-templates select="./INTERREF/IREF[@type='objectreference'][@tmodeltype='Business Process Requirements Model']" mode="referencedBusinessProcessRequirement"/>
<xsl:call-template name="elementPostProcessing"/>
	</xsl:template>
<xsl:template name="addReferencedBusinessProcessRequirement">		            
<xsl:param name="targetId"/>
bpaas:hasReferencedBusinessProcessRequirement data:<xsl:value-of select="$targetId"/> ;
</xsl:template>	 
<xsl:template match="IREF" mode="referencedBusinessProcessRequirement">
<xsl:call-template name="addReferencedBusinessProcessRequirement">
<xsl:with-param name="targetId" select="//MODEL[@modeltype=current()/@tmodeltype][@name=current()/@tmodelname][@name=current()/@tmodelname]/INSTANCE[@class=current()/@tclassname][@name=current()/@tobjname]/@id" />
</xsl:call-template>
</xsl:template>

<!-- ============== APQC Annotation ============== -->
<xsl:template name="APQCAnnotation">
	<xsl:if test="./ATTRIBUTE[@name='APQC Annotation'] !=''">
  rdf:type <xsl:value-of select="./ATTRIBUTE[@name='APQC Annotation']"/> ;
	</xsl:if> 
</xsl:template>
<!-- ============== Object Annotation ============== -->
<xsl:template name="ObjectAnnotation">
	<xsl:if test="./ATTRIBUTE[@name='Object Annotation'] !=''">
  rdf:type <xsl:value-of select="./ATTRIBUTE[@name='Object Annotation']"/> ;
	</xsl:if> 
</xsl:template>
<!-- ============== Action Annotation ============== -->
<xsl:template name="ActionAnnotation">
	<xsl:if test="./ATTRIBUTE[@name='Action Annotation'] !=''">
  rdf:type <xsl:value-of select="./ATTRIBUTE[@name='Action Annotation']"/> ;
	</xsl:if> 
</xsl:template>

	<!-- ============== Post Processing ============== -->
	<xsl:template name="elementPostProcessing">
		.
	</xsl:template>
</xsl:stylesheet>