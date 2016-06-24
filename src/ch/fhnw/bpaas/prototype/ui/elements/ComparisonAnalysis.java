package ch.fhnw.bpaas.prototype.ui.elements;

import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolution;
import org.apache.jena.query.ResultSet;

import ch.fhnw.bpaas.prototype.ontology.FilterAttributes;
import ch.fhnw.bpaas.prototype.ontology.OntologyManager;
import ch.fhnw.bpaas.prototype.ontology.StandardOperations;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;

public class ComparisonAnalysis {

	private SemanticObject businessProcess;
	private List<SemanticObject> workflowList;
	private OntologyManager ontology;
	private List<SemanticObject> businessProcessRequirementsList;
	
	private ArrayList<String> propertyBlackList;
	private ArrayList<String> valueBlackList;
	private ArrayList<String> filterList;
	
	private ObservableList<Map> allData = FXCollections.observableArrayList();
	
	public ComparisonAnalysis(OntologyManager ontology, SemanticObject businessProcess, List<SemanticObject> workflowList) {
		this.ontology = ontology;
		this.businessProcess = businessProcess;
		this.workflowList = workflowList;
		createAndFillBlackLists();
		createFilterList();
		
		queryBusinessProcessRequriements();
		analyseWorkflow();
	}
	
	private void createFilterList() {
		filterList = new ArrayList<String>();
	}
	
	private void createAndFillBlackLists() {
		propertyBlackList = new ArrayList<String>();
		propertyBlackList.add("http://www.w3.org/2000/01/rdf-schema#label");
		propertyBlackList.add("http://ikm-group.ch/archimeo/bpaas#hasDowntimePerMonthInMin");
		propertyBlackList.add("http://ikm-group.ch/archimeo/bpaas#BPRhasResponseTimeLevel");
		propertyBlackList.add("http://ikm-group.ch/archimeo/bpaas#BPRhasNumberOfProcessExecution");
		propertyBlackList.add("http://ikm-group.ch/archimeo/bpaas#BPRhasMediaType");
		
		
		valueBlackList = new ArrayList<String>();
		valueBlackList.add("http://ikm-group.ch/archimeo/bpaas#BusinessProcessRequirement");
	}

	private void analyseWorkflow(){
		for(SemanticObject wf : workflowList){
			allData.add(compareBP2WF(wf));
		}
	}
	

	private Map<String, String> compareBP2WF(SemanticObject wf) {
		Map<String, String> dataRow = new HashMap<>();
		dataRow.put("wf", wf.getName());
		for(SemanticObject bpr : businessProcessRequirementsList){
			ArrayList<SemanticObject> result = createRequirementsQuery(queryBusinessProcessRequirementsAttributes(bpr), wf);
			dataRow.put(bpr.getURI(), result.toString());
		}
		return dataRow;
	}

	private ArrayList<SemanticObject> createRequirementsQuery(ArrayList<Attribute> arrayList, SemanticObject workflow) {
		ArrayList<SemanticObject> temp = new ArrayList<SemanticObject>();
		ParameterizedSparqlString queryStr = new ParameterizedSparqlString();
		queryStr.append("SELECT ?wfd ?name WHERE {");
		queryStr.append("<"+workflow.getURI() +"> bpaas:hasReferencedWorkflowDescription ?wfd .");
		queryStr.append(genereateAttributeTriples(arrayList));
		queryStr.append("?wfd rdfs:label ?name .");
		queryStr.append(generateFilers());
		queryStr.append("}");
		
		ResultSet results = ontology.query(queryStr);
		
			while (results.hasNext()) {
				QuerySolution soln = results.next();
				temp.add(new SemanticObject(soln.get("wfd").toString(), soln.get("name").toString()));
			}
			return temp;
	}

	private ParameterizedSparqlString generateFilers() {
		ParameterizedSparqlString queryStr = new ParameterizedSparqlString();
		if(!filterList.isEmpty()){
			boolean first = true;
			queryStr.append("FILTER(");
			for(String filter : filterList){
				if(!first){
					queryStr.append("&&");
				}
				queryStr.append(filter);
				first = false;
			}
			queryStr.append(")");
			filterList.clear();
		}
		return queryStr;
	}

	private ParameterizedSparqlString genereateAttributeTriples(ArrayList<Attribute> arrayList) {
		ParameterizedSparqlString queryStr = new ParameterizedSparqlString();
		for(Attribute attribute : arrayList){
			if(!propertyBlackList.contains(attribute.getProperty()) && !valueBlackList.contains(attribute.getValue())){
				if(FilterAttributes.contains(attribute.getProperty())){
					FilterAttributes tempAttr = FilterAttributes.get(attribute.getProperty());
					queryStr.append("?wfd <" +attribute.getProperty() +"> " +tempAttr.getVariable() +" .");
					filterList.add(MessageFormat.format(tempAttr.getComparison(), StandardOperations.parseRange(attribute.getValue())));
				}else{
					queryStr.append("?wfd <" +attribute.getProperty() +"> <" +attribute.getValue() +"> .");
				}
			}
		}
		return queryStr;
	}

	private ArrayList<Attribute> queryBusinessProcessRequirementsAttributes(SemanticObject bpr) {
		ArrayList<Attribute> tempAttributes = new ArrayList<Attribute>();
		
		ParameterizedSparqlString queryStr = new ParameterizedSparqlString();
		queryStr.append("SELECT ?property ?value  WHERE {");
		queryStr.append("<"+bpr.getURI() +"> ?property ?value .");
		queryStr.append("}");

		ResultSet results = ontology.query(queryStr);

		while (results.hasNext()) {
			QuerySolution soln = results.next();
			String property = soln.get("property").toString();
			String value = soln.get("value").toString();
			
			tempAttributes.add(new Attribute(property, value));
		}
		return tempAttributes;
	}

	private void queryBusinessProcessRequriements(){
		businessProcessRequirementsList = new ArrayList<SemanticObject>();
		ParameterizedSparqlString queryStr = new ParameterizedSparqlString();
		queryStr.append("SELECT ?object ?name  WHERE {");
		queryStr.append("<"+businessProcess.getURI() +"> bpaas:hasReferencedBusinessProcessRequirement ?object .");
		queryStr.append("?object rdfs:label ?name .");
		queryStr.append("}");

		ResultSet results = ontology.query(queryStr);

		while (results.hasNext()) {
			QuerySolution soln = results.next();
			String name = soln.get("name").toString();
			String uri = soln.get("object").toString();
			
			businessProcessRequirementsList.add(new SemanticObject(uri, name));
		}
	}

	public List<SemanticObject> getBusinessProcessRequirements() {
		return businessProcessRequirementsList;
	}

	public ObservableList<Map> getAnalysisData() {
		return allData;
	}
}
