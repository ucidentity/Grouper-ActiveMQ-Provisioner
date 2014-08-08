package edu.cmu.is.grouper.dispatcher.util;

import static org.junit.Assert.assertTrue;

import javax.xml.bind.JAXBException;

import org.junit.Test;

import edu.cmu.is.grouper.dispatcher.ChangeLogMessage;
import edu.cmu.is.grouper.dispatcher.Dispatcher;

public class TestUnmarshallingMsg {

	@Test
	public void testStringAsReceived() throws JAXBException {
		String msg = "<operation>removeMember</operation><name>Community:AllContacts</name><memberId>psmbx-bcappo-2</memberId>";
		Dispatcher dispatcher = new Dispatcher();
		ChangeLogMessage clm = dispatcher.unmarshallXml(msg);
		assertTrue("member should have value of'psmbx-bcappo-2' ", clm.getMemberId().equals("psmbx-bcappo-2"));
	}

	@Test
	public void testMemberList() throws Exception {
		String msg = "<operation>fullSync</operation><name>cmu:pgh:AdministrativeComputing:PAS:office:testing</name><memberList><member>akshayag</member><member>pr14</member><member>ab8g</member><member>jl9r</member><member>rita</member><member>em1y</member><member>db4h</member></memberList>";
		Dispatcher dispatcher = new Dispatcher();
		ChangeLogMessage clm = dispatcher.unmarshallXml(msg);
		System.out.println("message -> " + clm);
		assertTrue("memberList should not be null!", clm.getMemberList() != null);
	}

	@Test
	public void testMessageWithAmpersand() throws Exception {
		String msg = "<operation>createGroup</operation><name><![CDATA[ Apps:ServiceNow:Assignment Groups:Communication & Documentation:AGManager ]]></name><description>null</description>";
		Dispatcher dispatcher = new Dispatcher();
		ChangeLogMessage clm = dispatcher.unmarshallXml(msg);
		assertTrue("Operation should have value of'createGroup' ", clm.getOperation().equals("createGroup"));
		System.out.println("groupName: " + clm.getGroupName());
	}
}
