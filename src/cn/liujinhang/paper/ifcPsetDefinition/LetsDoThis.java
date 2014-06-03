package cn.liujinhang.paper.ifcPsetDefinition;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.StringWriter;
import java.util.Properties;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public class LetsDoThis {

	public static void main(String[] args) {

		try {
			System.out.println("xsl loading start");

			Source xslSource = new StreamSource(new File(
					System.getProperty("user.dir") + "/psd/xsd2owl.xsl"));
			System.out.println("xsl loading end");

			System.out.println("xsd loading start");

			InputStreamReader xsdFileReader = new InputStreamReader(
					new FileInputStream(System.getProperty("user.dir")
							+ "/psd/PSD_IFC4_TC1_LOCAL.xsd"));

			Source xsdSource = new StreamSource(xsdFileReader);
			System.out.println("xsd loading end");

			TransformerFactory factory = TransformerFactory.newInstance(
					"net.sf.saxon.TransformerFactoryImpl", null);
			Transformer transformer = factory.newTransformer(xslSource);
			StringWriter writer = new StringWriter();

			System.out.println("translation start");
			transformer.transform(xsdSource, new StreamResult(writer));
			System.out.println("translation end");

			System.out.println("file output start");
			String result = new String(writer.getBuffer());
			result = result.replaceAll("&amp;", "&");

			File file = new File(System.getProperty("user.dir")
					+ "/psd/ifcOWL_phase_2_part.owl");

			BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(
					file));
			bufferedWriter.write(result);
			bufferedWriter.flush();
			bufferedWriter.close();
			System.out.println("file output end");
		} catch (Exception e) {
			e.printStackTrace();
		}

		try {

			System.out.println("file merging start");
			DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
			DocumentBuilder db = dbf.newDocumentBuilder();
			Document docMaster = db
					.parse("/Users/RYU/git/IfcTranslateProgram/ifc/ifcOWL_phase_1.owl");
			Document docSlave = db.parse(System.getProperty("user.dir")
					+ "/psd/ifcOWL_phase_2_part.owl");

			NodeList nodes = docSlave.getDocumentElement().getChildNodes();

			for (int i = 0; i < nodes.getLength(); i++) {
				Node firstDocImportedNode = docMaster.importNode(nodes.item(i),
						true);
				docMaster.getDocumentElement()
						.appendChild(firstDocImportedNode);
			}

			DOMSource source = new DOMSource(docMaster);
			File file = new File(System.getProperty("user.dir")
					+ "/psd/ifcOWL_phase_2.owl");
			StreamResult streamResult = new StreamResult(file);

			TransformerFactory factory = TransformerFactory.newInstance();
			Transformer transformer = factory.newTransformer();
			Properties properties = transformer.getOutputProperties();
			properties.setProperty(OutputKeys.ENCODING, "UTF-8");
			transformer.setOutputProperties(properties);
			transformer.transform(source, streamResult);
			System.out.println("file merging end");

		} catch (Exception e) {
			e.printStackTrace();
		}

	}
}
