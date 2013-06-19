<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Edit metadata form
  -
  - Attributes to pass in to this page:
  -    submission.info   - the SubmissionInfo object
  -    submission.inputs - the DCInputSet
  -    submission.page   - the step in submission
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.net.URLEncoder" %>

<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="javax.servlet.jsp.tagext.TagSupport" %>
<%@ page import="javax.servlet.jsp.PageContext" %>
<%@ page import="javax.servlet.ServletException" %>

<%@ page import="org.dspace.core.Context" %>
<%@ page import="org.dspace.app.webui.jsptag.PopupTag" %>
<%@ page import="org.dspace.app.util.DCInput" %>
<%@ page import="org.dspace.app.util.DCInputSet" %>
<%@ page import="org.dspace.app.webui.servlet.SubmissionController" %>
<%@ page import="org.dspace.submit.AbstractProcessingStep" %>
<%@ page import="org.dspace.core.I18nUtil" %>
<%@ page import="org.dspace.app.webui.util.JSPManager" %>
<%@ page import="org.dspace.app.util.SubmissionInfo" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.content.DCDate" %>
<%@ page import="org.dspace.content.DCLanguage" %>
<%@ page import="org.dspace.content.DCPersonName" %>
<%@ page import="org.dspace.content.DCSeriesNumber" %>
<%@ page import="org.dspace.content.DCValue" %>
<%@ page import="org.dspace.content.Item" %>
<%@ page import="org.dspace.content.authority.MetadataAuthorityManager" %>
<%@ page import="org.dspace.content.authority.ChoiceAuthorityManager" %>
<%@ page import="org.dspace.content.authority.Choices" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%
    request.setAttribute("LanguageSwitch", "hide");
%>
<%!
    // required by Controlled Vocabulary  add-on and authority addon
        String contextPath;

    // An unknown value of confidence for new, empty input fields,
    // so no icon appears yet.
    int unknownConfidence = Choices.CF_UNSET - 100;

    // This method is resposible for showing a link next to an input box
    // that pops up a window that to display a controlled vocabulary.
    // It should be called from the doOneBox and doTwoBox methods.
    // It must be extended to work with doTextArea.
    String doControlledVocabulary(String fieldName, PageContext pageContext, String vocabulary, boolean readonly)
    {
        String link = "";
        boolean enabled = ConfigurationManager.getBooleanProperty("webui.controlledvocabulary.enable");
        boolean useWithCurrentField = vocabulary != null && ! "".equals(vocabulary);
        
        if (enabled && useWithCurrentField && !readonly)
        {
                        // Deal with the issue of _0 being removed from fieldnames in the configurable submission system
                        if (fieldName.endsWith("_0"))
                        {
                                fieldName = fieldName.substring(0, fieldName.length() - 2);
                        }
                        link = "<br/>" +
                        "<a href='javascript:void(null);' onclick='javascript:popUp(\"" +
                                contextPath + "/controlledvocabulary/controlledvocabulary.jsp?ID=" +
                                fieldName + "&amp;vocabulary=" + vocabulary + "\")'>" +
                                        "<span class='controlledVocabularyLink'>" +
                                                LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.controlledvocabulary") +
                                        "</span>" +
                        "</a>";
                }

                return link;
    }

    boolean hasVocabulary(String vocabulary)
    {
        boolean enabled = ConfigurationManager.getBooleanProperty("webui.controlledvocabulary.enable");
        boolean useWithCurrentField = vocabulary != null && !"".equals(vocabulary);
        boolean has = false;
        
        if (enabled && useWithCurrentField)
        {
                has = true;
        }
        return has;
    }

    // is this field going to be rendered as Choice-driven <select>?
    boolean isSelectable(String fieldKey)
    {
        ChoiceAuthorityManager cam = ChoiceAuthorityManager.getManager();
        return (cam.isChoicesConfigured(fieldKey) &&
            "select".equals(cam.getPresentation(fieldKey)));
    }

    // Render the choice/authority controlled entry, or, if not indicated,
    // returns the given default inputBlock
    StringBuffer doAuthority(PageContext pageContext, String fieldName,
            int idx, int fieldCount, String fieldInput, String authorityValue,
            int confidenceValue, boolean isName, boolean repeatable,
            DCValue[] dcvs, StringBuffer inputBlock, int collectionID)
    {
        MetadataAuthorityManager mam = MetadataAuthorityManager.getManager();
        ChoiceAuthorityManager cam = ChoiceAuthorityManager.getManager();
        StringBuffer sb = new StringBuffer();

        if (cam.isChoicesConfigured(fieldName))
        {
            boolean authority = mam.isAuthorityControlled(fieldName);
            boolean required = authority && mam.isAuthorityRequired(fieldName);
            boolean isSelect = "select".equals(cam.getPresentation(fieldName)) && !isName;

            // if this is not the only or last input, append index to input @names
            String authorityName = fieldName + "_authority";
            String confidenceName = fieldName + "_confidence";
            if (repeatable && !isSelect && idx != fieldCount-1)
            {
                fieldInput += '_'+String.valueOf(idx+1);
                authorityName += '_'+String.valueOf(idx+1);
                confidenceName += '_'+String.valueOf(idx+1);
            }

            String confidenceSymbol = confidenceValue == unknownConfidence ? "blank" : Choices.getConfidenceText(confidenceValue).toLowerCase();
            String confIndID = fieldInput+"_confidence_indicator_id";
            if (authority)
            {
                sb.append(" <img id=\""+confIndID+"\" title=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.authority.confidence.description."+confidenceSymbol))
                  .append("\" class=\"ds-authority-confidence cf-")
                  // set confidence to cf-blank if authority is empty
                  .append(authorityValue==null||authorityValue.length()==0 ? "blank" : confidenceSymbol)
                  .append(" \" src=\"").append(contextPath).append("/image/confidence/invisible.gif\" />")
                  .append("<input type=\"text\" value=\"").append(authorityValue!=null?authorityValue:"")
                  .append("\" id=\"").append(authorityName)
                  .append("\" name=\"").append(authorityName).append("\" class=\"ds-authority-value\"/>")
                  .append("<input type=\"hidden\" value=\"").append(confidenceSymbol)
                  .append("\" id=\"").append(confidenceName)
                  .append("\" name=\"").append(confidenceName)
                  .append("\" class=\"ds-authority-confidence-input\"/>");
            }

            // suggest is not supported for name input type
            if ("suggest".equals(cam.getPresentation(fieldName)) && !isName)
            {
                if (inputBlock != null)
                    sb.insert(0, inputBlock);
                sb.append("<span id=\"").append(fieldInput).append("_indicator\" style=\"display: none;\">")
                  .append("<img src=\"").append(contextPath).append("/image/authority/load-indicator.gif\" alt=\"Loading...\"/>")
                  .append("</span><div id=\"").append(fieldInput).append("_autocomplete\" class=\"autocomplete\" style=\"display: none;\"> </div>");

                sb.append("<script type=\"text/javascript\">")
                  .append("var gigo = DSpaceSetupAutocomplete('edit_metadata',")
                  .append("{ metadataField: '").append(fieldName).append("', isClosed: '").append(required?"true":"false").append("', inputName: '")
                  .append(fieldInput).append("', authorityName: '").append(authorityName).append("', containerID: '")
                  .append(fieldInput).append("_autocomplete', indicatorID: '").append(fieldInput).append("_indicator', ")
                  .append("contextPath: '").append(contextPath)
                  .append("', confidenceName: '").append(confidenceName)
                  .append("', confidenceIndicatorID: '").append(confIndID)
                  .append("', collection: ").append(String.valueOf(collectionID))
                  .append(" }); </script>");
            }

            // put up a SELECT element containing all choices
            else if (isSelect)
            {
                sb.append("<select id=\"").append(fieldInput)
                   .append("_id\" name=\"").append(fieldInput)
                   .append("\" size=\"").append(String.valueOf(repeatable ? 6 : 1))
                   .append(repeatable ? "\" multiple>\n" :"\">\n");
                Choices cs = cam.getMatches(fieldName, "", collectionID, 0, 0, null);
                // prepend unselected empty value when nothing can be selected.
                if (!repeatable && cs.defaultSelected < 0 && dcvs.length == 0)
                    sb.append("<option value=\"\"><!-- empty --></option>\n");
                for (int i = 0; i < cs.values.length; ++i)
                {
                    boolean selected = false;
                    for (DCValue dcv : dcvs)
                    {
                        if (dcv.value.equals(cs.values[i].value))
                            selected = true;
                    }
                    sb.append("<option value=\"")
                      .append(cs.values[i].value.replaceAll("\"", "\\\""))
                      .append("\"")
                      .append(selected ? " selected>":">")
                      .append(cs.values[i].label).append("</option>\n");
                }
                sb.append("</select>\n");
            }

              // use lookup for any other presentation style (i.e "select")
            else
            {
                if (inputBlock != null)
                    sb.insert(0, inputBlock);
                sb.append("<input type=\"image\" name=\"").append(fieldInput).append("_lookup\" ")
                  .append("onclick=\"javascript: return DSpaceChoiceLookup('")
                  .append(contextPath).append("/tools/lookup.jsp','")
                  .append(fieldName).append("','edit_metadata','")
                  .append(fieldInput).append("','").append(authorityName).append("','")
                  .append(confIndID).append("',")
                  .append(String.valueOf(collectionID)).append(",")
                  .append(String.valueOf(isName)).append(",false);\"")
                  .append(" title=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.tools.lookup.lookup"))
                  .append("\" width=\"16px\" height=\"16px\" src=\""+contextPath+"/image/authority/zoom.png\" />");
            }
        }
        else if (inputBlock != null)
            sb = inputBlock;
        return sb;
    }

    void doPersonalName(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable,
      boolean readonly, int fieldCountIncr, String label, PageContext pageContext, int collectionID)
      throws java.io.IOException
    {

      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      int fieldCount = defaults.length + fieldCountIncr;
      StringBuffer headers = new StringBuffer();
      StringBuffer sb = new StringBuffer();
      org.dspace.content.DCPersonName dpn;
      String auth;
      int conf = 0;
      StringBuffer name = new StringBuffer();
      StringBuffer first = new StringBuffer();
      StringBuffer last = new StringBuffer();
      
      if (fieldCount == 0)
         fieldCount = 1;

      //Width hints used here to affect whole table
      headers.append("<tr><td width=\"40%\">&nbsp;</td>")
             .append("<td class=\"submitFormDateLabel\" width=\"5%\">")
//             .append("Last name<br>e.g. <strong>Smith</strong></td>")
                         .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.lastname"))
                         .append("</td>")
             .append("<td class=\"submitFormDateLabel\" width=\"5%\">")
//             .append("First name(s) + \"Jr\"<br> e.g. <strong>Donald Jr</strong></td>")
                         .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.firstname"))
                         .append("</td>")
             .append("<td width=\"40%\">&nbsp;</td>")
             .append("</tr>");
      out.write(headers.toString());


      for (int i = 0; i < fieldCount; i++)
      {
         first.setLength(0);
         first.append(fieldName).append("_first");
         if (repeatable && i != fieldCount-1)
            first.append('_').append(i+1);

         last.setLength(0);
         last.append(fieldName).append("_last");
         if (repeatable && i != fieldCount-1)
            last.append('_').append(i+1);
            
         if (i == 0)
            sb.append("<tr><td class=\"submitFormLabel\">")
              .append(label)
              .append("</td>");
         else
            sb.append("<tr><td>&nbsp;</td>");

         if (i < defaults.length)
         {
            dpn = new org.dspace.content.DCPersonName(defaults[i].value);
            auth = defaults[i].authority;
            conf = defaults[i].confidence;
         }
         else
         {
            dpn = new org.dspace.content.DCPersonName();
            auth = "";
            conf = unknownConfidence;
         }
         
         sb.append("<td><input type=\"text\" name=\"")
           .append(last.toString())
           .append("\" size=\"23\" ");
         if (readonly)
         {
             sb.append("disabled=\"disabled\" ");
         }
         sb.append("value=\"")
           .append(dpn.getLastName().replaceAll("\"", "&quot;")) // Encode "
                   .append("\"/></td>\n<td nowrap=\"nowrap\"><input type=\"text\" name=\"")
                   .append(first.toString())
           .append("\" size=\"23\" ");
         if (readonly)
         {
             sb.append("disabled=\"disabled\" ");
         }
         sb.append("value=\"")
         .append(dpn.getFirstNames()).append("\"/>")
           .append(doAuthority(pageContext, fieldName, i, fieldCount, fieldName,
                auth, conf, true, repeatable, defaults, null, collectionID))
           .append("</td>\n");

         if (repeatable && !readonly && i < defaults.length)
         {
            name.setLength(0);
            name.append(dpn.getLastName())
                .append(' ')
                .append(dpn.getFirstNames());
            // put a remove button next to filled in values
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
              .append("_remove_")
              .append(i)
//            .append("\" value=\"Remove This Entry\"/> </td></tr>")
                  .append("\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                  .append("\"/> </td></tr>");
         }
         else if (repeatable && !readonly && i == fieldCount - 1)
         {
            // put a 'more' button next to the last space
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
//            .append("_add\" value=\"Add More\"/> </td></tr>");
              .append("_add\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
              .append("\"/> </td></tr>");
         }
         else
         {
            // put a blank if nothing else
            sb.append("<td>&nbsp;</td></tr>");
         }
      }

      out.write(sb.toString());
    }

    void doDate(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable,
      boolean readonly, int fieldCountIncr, String label, PageContext pageContext, HttpServletRequest request)
      throws java.io.IOException
    {

      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      int fieldCount = defaults.length + fieldCountIncr;
      StringBuffer sb = new StringBuffer();
      org.dspace.content.DCDate dateIssued;

      if (fieldCount == 0)
         fieldCount = 1;

      for (int i = 0; i < fieldCount; i++)
      {
         if (i == 0)
            sb.append("<tr><td class=\"submitFormLabel\">")
              .append(label)
              .append("</td>");
         else
            sb.append("<tr><td>&nbsp;</td>");

         if (i < defaults.length)
            dateIssued = new org.dspace.content.DCDate(defaults[i].value);
         else
            dateIssued = new org.dspace.content.DCDate("");
    
         sb.append("<td colspan=\"2\" nowrap=\"nowrap\" class=\"submitFormDateLabel\">")
//          .append("Month:<select name=\"")
                .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.month"))
            .append("<select name=\"")
            .append(fieldName)
            .append("_month");
         if (repeatable && i>0)
         {
            sb.append('_').append(i);
         }
         if (readonly)
         {
             sb.append("\" disabled=\"disabled");
         }
         sb.append("\"><option value=\"-1\"")
            .append((dateIssued.getMonth() == -1 ? " selected=\"selected\"" : ""))
//          .append(">(No month)</option>");
            .append(">")
            .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.no_month"))
            .append("</option>");
            
         for (int j = 1; j < 13; j++)
         {
            sb.append("<option value=\"")
              .append(j)
              .append((dateIssued.getMonth() == j ? "\" selected=\"selected\"" : "\"" ))
              .append(">")
              .append(org.dspace.content.DCDate.getMonthName(j,I18nUtil.getSupportedLocale(request.getLocale())))
              .append("</option>");
         }
    
         sb.append("</select>")
//            .append("Day:<input type=text name=\"")
                .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.day"))
                .append("<input type=\"text\" name=\"")
            .append(fieldName)
            .append("_day");
         if (repeatable && i>0)
            sb.append("_").append(i);
         if (readonly)
         {
             sb.append("\" disabled=\"disabled");
         }
         sb.append("\" size=\"2\" maxlength=\"2\" value=\"")
            .append((dateIssued.getDay() > 0 ?
                     String.valueOf(dateIssued.getDay()) : "" ))
//          .append("\"/>Year:<input type=text name=\"")
                .append("\"/>")
                .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.year"))
                .append("<input type=\"text\" name=\"")
            .append(fieldName)
            .append("_year");
         if (repeatable && i>0)
            sb.append("_").append(i);
         if (readonly)
         {
             sb.append("\" disabled=\"disabled");
         }
         sb.append("\" size=\"4\" maxlength=\"4\" value=\"")
            .append((dateIssued.getYear() > 0 ?
                 String.valueOf(dateIssued.getYear()) : "" ))
            .append("\"/></td>\n");
    
         if (repeatable && !readonly && i < defaults.length)
         {
            // put a remove button next to filled in values
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
              .append("_remove_")
              .append(i)
//            .append("\" value=\"Remove This Entry\"/> </td></tr>");
                  .append("\" value=\"")
                  .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
                  .append("\"/> </td></tr>");
         }
         else if (repeatable && !readonly && i == fieldCount - 1)
         {
            // put a 'more' button next to the last space
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
//            .append("_add\" value=\"Add More\"/> </td></tr>");
              .append("_add\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
              .append("\"/> </td></tr>");
         }
         else
         {
            // put a blank if nothing else
            sb.append("<td>&nbsp;</td></tr>");
         }
      }

      out.write(sb.toString());
    }

    void doSeriesNumber(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable,
      boolean readonly, int fieldCountIncr, String label, PageContext pageContext)
      throws java.io.IOException
    {

      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      int fieldCount = defaults.length + fieldCountIncr;
      StringBuffer sb = new StringBuffer();
      org.dspace.content.DCSeriesNumber sn;
      StringBuffer headers = new StringBuffer();

      //Width hints used here to affect whole table
      headers.append("<tr><td width=\"40%\">&nbsp;</td>")
          .append("<td class=\"submitFormDateLabel\" width=\"5%\">")
//          .append("Series Name</td>")
                         .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.seriesname"))
          .append("</td>")
          .append("<td class=\"submitFormDateLabel\" width=\"5%\">")
//          .append("Report or Paper No.</td>")
                         .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.paperno"))
          .append("</td>")
          .append("<td width=\"40%\">&nbsp;</td>")
          .append("</tr>");
      out.write(headers.toString());
      
      
      if (fieldCount == 0)
         fieldCount = 1;

      for (int i = 0; i < fieldCount; i++)
      {
         if (i == 0)
            sb.append("<tr><td class=\"submitFormLabel\">")
              .append(label)
              .append("</td>");
         else
            sb.append("<tr><td>&nbsp;</td>");

         if (i < defaults.length)
           sn = new org.dspace.content.DCSeriesNumber(defaults[i].value);
         else
           sn = new org.dspace.content.DCSeriesNumber();

         sb.append("<td><input type=\"text\" name=\"")
           .append(fieldName)
           .append("_series");
         if (repeatable && i!= fieldCount)
           sb.append("_").append(i+1);
         if (readonly)
         {
             sb.append("\" disabled=\"disabled");
         }
         sb.append("\" size=\"23\" value=\"")
           .append(sn.getSeries().replaceAll("\"", "&quot;"))
           .append("\"/></td>\n<td><input type=\"text\" name=\"")
           .append(fieldName)
           .append("_number");
         if (repeatable && i!= fieldCount)
           sb.append("_").append(i+1);
         if (readonly)
         {
             sb.append("\" disabled=\"disabled");
         }
         sb.append("\" size=\"23\" value=\"")
           .append(sn.getNumber().replaceAll("\"", "&quot;"))
           .append("\"/></td>\n");

         if (repeatable && !readonly && i < defaults.length)
         {
            // put a remove button next to filled in values
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
              .append("_remove_")
              .append(i)
//            .append("\" value=\"Remove This Entry\"/> </td></tr>");
              .append("\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
              .append("\"/> </td></tr>");
         }
         else if (repeatable && !readonly && i == fieldCount - 1)
         {
            // put a 'more' button next to the last space
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
//            .append("_add\" value=\"Add More\"/> </td></tr>");
              .append("_add\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
              .append("\"/> </td></tr>");
         }
         else
         {
            // put a blank if nothing else
            sb.append("<td>&nbsp;</td></tr>");
         }
      }

      out.write(sb.toString());
    }

    void doTextArea(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean readonly,
      int fieldCountIncr, String label, PageContext pageContext, String vocabulary, boolean closedVocabulary, int collectionID)
      throws java.io.IOException
    {

      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      int fieldCount = defaults.length + fieldCountIncr;
      StringBuffer sb = new StringBuffer();
      String val, auth;
      int conf = unknownConfidence;

      if (fieldCount == 0)
         fieldCount = 1;

      for (int i = 0; i < fieldCount; i++)
      {
         if (i == 0)
            sb.append("<tr><td class=\"submitFormLabel\">")
              .append(label)
              .append("</td>");
         else
            sb.append("<tr><td>&nbsp;</td>");

         if (i < defaults.length)
         {
           val = defaults[i].value;
              auth = defaults[i].authority;
              conf = defaults[i].confidence;
         }
         else
         {
           val = "";
            auth = "";
         }
         sb.append("<td colspan=\"2\">\n");
         String fieldNameIdx = fieldName + ((repeatable && i != fieldCount-1)?"_" + (i+1):"");
         StringBuffer inputBlock = new StringBuffer().append("<textarea name=\"").append(fieldNameIdx)
           .append("\" rows=\"4\" cols=\"45\" id=\"")
           .append(fieldNameIdx).append("_id\" ")
           .append((hasVocabulary(vocabulary)&&closedVocabulary)||readonly?" disabled=\"disabled\" ":"")
           .append(">")
           .append(val)
           .append("</textarea>\n")
           .append(doControlledVocabulary(fieldNameIdx, pageContext, vocabulary, readonly));
         sb.append(doAuthority(pageContext, fieldName, i, fieldCount, fieldName,
                            auth, conf, false, repeatable,
                            defaults, inputBlock, collectionID))
           .append("</td>\n");

         if (repeatable && !readonly && i < defaults.length)
         {
            // put a remove button next to filled in values
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
              .append("_remove_")
              .append(i)
//            .append("\" value=\"Remove This Entry\"/> </td></tr>");
              .append("\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
              .append("\"/> </td></tr>");
         }
         else if (repeatable && !readonly && i == fieldCount - 1)
         {
            // put a 'more' button next to the last space
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
//            .append("_add\" value=\"Add More\"/> </td></tr>");
              .append("_add\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
              .append("\"/> </td></tr>");
         }
         else
         {
            // put a blank if nothing else
            sb.append("<td>&nbsp;</td></tr>");
         }
      }

      out.write(sb.toString());
    }

    void doOneBox(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean readonly,
      int fieldCountIncr, String label, PageContext pageContext, String vocabulary, boolean closedVocabulary, int collectionID)
      throws java.io.IOException
    {

      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      int fieldCount = defaults.length + fieldCountIncr;
      StringBuffer sb = new StringBuffer();
      String val, auth;
      int conf= 0;

      if (fieldCount == 0)
         fieldCount = 1;

        for (int i = 0; i < fieldCount; i++)
        {
           if (i == 0)
              sb.append("<tr><td class=\"submitFormLabel\">")
                .append(label)
                .append("</td>");
           else
              sb.append("<tr><td>&nbsp;</td>");
         
           if (i < defaults.length)
           {
             val = defaults[i].value.replaceAll("\"", "&quot;");
             auth = defaults[i].authority;
             conf = defaults[i].confidence;
           }
           else
           {
             val = "";
             auth = "";
             conf= unknownConfidence;
           }

           sb.append("<td colspan=\"2\">");
           String fieldNameIdx = fieldName + ((repeatable && i != fieldCount-1)?"_" + (i+1):"");
           StringBuffer inputBlock = new StringBuffer("<input type=\"text\" name=\"")
             .append(fieldNameIdx)
             .append("\" id=\"")
             .append(fieldNameIdx).append("\" size=\"50\" value=\"")
             .append(val +"\"")
             .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
             .append("/>")
             .append(doControlledVocabulary(fieldNameIdx, pageContext, vocabulary, readonly))
             .append("\n");
           sb.append(doAuthority(pageContext, fieldName, i,  fieldCount,
                              fieldName, auth, conf, false, repeatable,
                              defaults, inputBlock, collectionID))
             .append("</td>\n");

          if (repeatable && !readonly && i < defaults.length)
          {
             // put a remove button next to filled in values
             sb.append("<td><input type=\"submit\" name=\"submit_")
               .append(fieldName)
               .append("_remove_")
               .append(i)
//             .append("\" value=\"Remove This Entry\"/> </td></tr>");
               .append("\" value=\"")
               .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
               .append("\"/> </td></tr>");
          }
          else if (repeatable && !readonly && i == fieldCount - 1)
          {
             // put a 'more' button next to the last space
             sb.append("<td><input type=\"submit\" name=\"submit_")
               .append(fieldName)
//             .append("_add\" value=\"Add More\"/> </td></tr>");
               .append("_add\" value=\"")
               .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
               .append("\"/> </td></tr>");
          }
          else
          {
             // put a blank if nothing else
             sb.append("<td>&nbsp;</td></tr>");
          }
        }

      out.write(sb.toString());
    }

    void doTwoBox(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable, boolean readonly,
      int fieldCountIncr, String label, PageContext pageContext, String vocabulary, boolean closedVocabulary)
      throws java.io.IOException
    {
      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      int fieldCount = defaults.length + fieldCountIncr;
      StringBuffer sb = new StringBuffer();
      StringBuffer headers = new StringBuffer();

      String fieldParam = "";
      
      if (element.equals("relation") && qualifier.equals("ispartofseries"))
      {
         //Width hints used here to affect whole table
         headers.append("<tr><td width=\"40%\">&nbsp;</td>")
             .append("<td class=\"submitFormDateLabel\" width=\"5%\">")
//             .append("Series Name</td>")
                         .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.seriesname"))
             .append("</td>")
             .append("<td class=\"submitFormDateLabel\" width=\"5%\">")
//             .append("Report or Paper No.</td>")
                         .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.paperno"))
             .append("</td>")
             .append("<td width=\"40%\">&nbsp;</td>")
             .append("</tr>");
         out.write(headers.toString());
      }

      if (fieldCount == 0)
         fieldCount = 1;

      for (int i = 0; i < fieldCount; i++)
      {
                 if (i == 0)
                 {
                    sb.append("<tr><td class=\"submitFormLabel\">")
                      .append(label)
                      .append("</td>");
                 }
                 else
                 {
                    sb.append("<tr><td>&nbsp;</td>");
                 }
                 
                 if(i != fieldCount)
                 {
                         //param is field name and index, starting from 1 (e.g. myfield_2)
                     fieldParam = fieldName + "_" + (i+1);
                 }
                 else
                 {
                         //param is just the field name
                         fieldParam = fieldName;
                 }
                 
         if (i < defaults.length)
         {
           sb.append("<td align=\"left\"><input type=\"text\" name=\"")
             .append(fieldParam)
             .append("\" size=\"15\" value=\"")
             .append(defaults[i].value.replaceAll("\"", "&quot;"))
             .append("\"")
             .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
             .append("/>");
          if (!readonly)
          {
                       sb.append("&nbsp;<input type=\"submit\" name=\"submit_")
                             .append(fieldName)
                             .append("_remove_")
                             .append(i)
                             .append("\" value=\"")
                             .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove2"))
                             .append("\"/>");
          }
          sb.append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly))
                .append("</td>\n");
         }
         else
                 {
           sb.append("<td align=\"left\"><input type=\"text\" name=\"")
             .append(fieldParam)
             .append("\" size=\"15\"")
             .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
             .append("/>")
             .append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly))
             .append("</td>\n");
                }
         
         i++;

         if(i != fieldCount)
                 {
                         //param is field name and index, starting from 1 (e.g. myfield_2)
                     fieldParam = fieldName + "_" + (i+1);
                 }
                 else
                 {
                         //param is just the field name
                         fieldParam = fieldName;
                 }
        
                 if (i < defaults.length)
                 {
                   sb.append("<td align=\"left\"><input type=\"text\" name=\"")
                     .append(fieldParam)
                     .append("\" size=\"15\" value=\"")
                     .append(defaults[i].value.replaceAll("\"", "&quot;"))
                         .append("\"")
                         .append((hasVocabulary(vocabulary)&&closedVocabulary) || readonly?" disabled=\"disabled\" ":"")
                         .append("/>");
                   if (!readonly)
                   {
                               sb.append("&nbsp;<input type=\"submit\" name=\"submit_")
                                     .append(fieldName)
                                     .append("_remove_")
                                     .append(i)
                                     .append("\" value=\"")
                                     .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove2"))
                                     .append("\"/>");
                   }
                        
                   sb.append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly))
                         .append("</td></tr>\n");
                 }
                 else
                 {
                   sb.append("<td align=\"left\"><input type=\"text\" name=\"")
                     .append(fieldParam)
                     //.append("\" size=\"15\"/></td>");
                     .append("\" size=\"15\"")
                     .append((hasVocabulary(vocabulary)&&closedVocabulary)||readonly?" disabled=\"disabled\" ":"")
                     .append("/>")
                     .append(doControlledVocabulary(fieldParam, pageContext, vocabulary, readonly))
                     .append("</td>\n");
        
                   if (i+1 >= fieldCount && !readonly)
                   {
                     sb.append("<td><input type=\"submit\" name=\"submit_")
                       .append(fieldName)
                       .append("_add\" value=\"")
                       .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
                       .append("\"/></td>\n");
                   }
                   else
                   {
                     sb.append("</td>");
                   }
                   sb.append("<td>&nbsp;</td></tr>");
                 }
      }

      out.write(sb.toString());
    }
    
    

    void doQualdropValue(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, DCInputSet inputs, boolean repeatable,
      boolean readonly, int fieldCountIncr, List qualMap, String label, PageContext pageContext)
      throws java.io.IOException
    {
                DCValue[] unfiltered = item.getMetadata(schema, element, Item.ANY, Item.ANY);
                // filter out both unqualified and qualified values occurring elsewhere in inputs
                List<DCValue> filtered = new ArrayList<DCValue>();
                for (int i = 0; i < unfiltered.length; i++)
                {
                    String unfilteredFieldName = unfiltered[i].element;
                    if(unfiltered[i].qualifier != null && unfiltered[i].qualifier.length()>0)
                        unfilteredFieldName += "." + unfiltered[i].qualifier;
                        
                        if ( ! inputs.isFieldPresent(unfilteredFieldName) )
                        {
                                filtered.add( unfiltered[i] );
                        }
                }
                DCValue[] defaults = filtered.toArray(new DCValue[0]);
      //DCValue[] defaults = item.getMetadata(element, Item.ANY, Item.ANY);
      int fieldCount = defaults.length + fieldCountIncr;
      StringBuffer sb = new StringBuffer();
      String   q, v, currentQual, currentVal;

      if (fieldCount == 0)
         fieldCount = 1;

      for (int j = 0; j < fieldCount; j++)
      {

         if (j < defaults.length)
         {
            currentQual = defaults[j].qualifier;
            if(currentQual==null) currentQual="";
            currentVal = defaults[j].value;
         }
         else
         {
            currentQual = "";
            currentVal = "";
         }

         if (j == 0)
            sb.append("<tr><td class=\"submitFormLabel\">")
              .append(label)
              .append("</td>");
         else
            sb.append("<tr><td>&nbsp;</td>");

         // do the dropdown box
         sb.append("<td colspan=\"2\"><select name=\"")
           .append(fieldName)
           .append("_qualifier");
         if (repeatable && j!= fieldCount-1)
           sb.append("_").append(j+1);
         if (readonly)
         {
             sb.append("\" disabled=\"disabled");
         }
         sb.append("\">");
         for (int i = 0; i < qualMap.size(); i+=2)
         {
           q = (String)qualMap.get(i);
           v = (String)qualMap.get(i+1);
           sb.append("<option")
             .append((v.equals(currentQual) ? " selected=\"selected\" ": "" ))
             .append(" value=\"")
             .append(v)
             .append("\">")
             .append(q)
             .append("</option>");
         }
      
         // do the input box
         sb.append("</select>&nbsp;<input type=\"text\" name=\"")
           .append(fieldName)
           .append("_value");
         if (repeatable && j!= fieldCount-1)
           sb.append("_").append(j+1);
         if (readonly)
         {
             sb.append("\" disabled=\"disabled");
         }
         sb.append("\" size=\"34\" value=\"")
           .append(currentVal.replaceAll("\"", "&quot;"))
           .append("\"/></td>\n");

         if (repeatable && !readonly && j < defaults.length)
         {
            // put a remove button next to filled in values
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
              .append("_remove_")
              .append(j)
//            .append("\" value=\"Remove This Entry\"/> </td></tr>");
              .append("\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.remove"))
              .append("\"/> </td></tr>");
         }
         else if (repeatable && !readonly && j == fieldCount - 1)
         {
            // put a 'more' button next to the last space
            sb.append("<td><input type=\"submit\" name=\"submit_")
              .append(fieldName)
//            .append("_add\" value=\"Add More\"/> </td></tr>");
              .append("_add\" value=\"")
              .append(LocaleSupport.getLocalizedMessage(pageContext, "jsp.submit.edit-metadata.button.add"))
              .append("\"/> </td></tr>");
         }
         else
         {
            // put a blank if nothing else
            sb.append("<td>&nbsp;</td></tr>");
         }
      }

      out.write(sb.toString());
    }

    void doDropDown(javax.servlet.jsp.JspWriter out, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable,
      boolean readonly, List valueList, String label)
      throws java.io.IOException
    {
      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      StringBuffer sb = new StringBuffer();
      Iterator vals;
      String display, value;
      int j;

      sb.append("<tr><td class=\"submitFormLabel\">")
        .append(label)
        .append("</td>");

      sb.append("<td colspan=\"2\">")
        .append("<select name=\"")
        .append(fieldName)
        .append("\"");
      if (repeatable)
        sb.append(" size=\"6\"  multiple=\"multiple\"");
      if (readonly)
      {
          sb.append(" disabled=\"disabled\"");
      }
      sb.append(">");

      for (int i = 0; i < valueList.size(); i += 2)
      {
         display = (String)valueList.get(i);
         value = (String)valueList.get(i+1);
         for (j = 0; j < defaults.length; j++)
         {
             if (value.equals(defaults[j].value))
                 break;
         }
         sb.append("<option ")
           .append(j < defaults.length ? " selected=\"selected\" " : "")
           .append("value=\"")
           .append(value.replaceAll("\"", "&quot;"))
           .append("\">")
           .append(display)
           .append("</option>");
      }

      sb.append("</select></td></tr>");
      out.write(sb.toString());
    }
    
    void doChoiceSelect(javax.servlet.jsp.JspWriter out, PageContext pageContext, Item item,
      String fieldName, String schema, String element, String qualifier, boolean repeatable,
      boolean readonly, List valueList, String label, int collectionID)
      throws java.io.IOException
    {
      DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
      StringBuffer sb = new StringBuffer();

      sb.append("<tr><td class=\"submitFormLabel\">")
        .append(label)
        .append("</td>");
      sb.append("<td colspan=\"2\">")
        .append(doAuthority(pageContext, fieldName, 0,  defaults.length,
                              fieldName, null, Choices.CF_UNSET, false, repeatable,
                              defaults, null, collectionID))

        .append("</td></tr>");
      out.write(sb.toString());
    }


    
    /** Display Checkboxes or Radio buttons, depending on if repeatable! **/
    void doList(javax.servlet.jsp.JspWriter out, Item item,
            String fieldName, String schema, String element, String qualifier, boolean repeatable,
            boolean readonly, List valueList, String label)
            throws java.io.IOException
          {
                DCValue[] defaults = item.getMetadata(schema, element, qualifier, Item.ANY);
                int valueCount = valueList.size();
                
            StringBuffer sb = new StringBuffer();
            String display, value;
            int j;

            int numColumns = 1;
            //if more than 3 display+value pairs, display in 2 columns to save space
            if(valueCount > 6)
                numColumns = 2;

            //print out the field label
            sb.append("<tr><td class=\"submitFormLabel\">")
                  .append(label)
                  .append("</td>");
            
            if(numColumns > 1)
                sb.append("<td valign=\"top\">");
            else
                sb.append("<td valign=\"top\" colspan=\"3\">");
            
            //flag that lets us know when we are in Column2
            boolean inColumn2 = false;
            
            //loop through all values
            for (int i = 0; i < valueList.size(); i += 2)
            {
                           //get display value and actual value
               display = (String)valueList.get(i);
                   value = (String)valueList.get(i+1);
         
                   //check if this value has been selected previously
                   for (j = 0; j < defaults.length; j++)
                   {
                        if (value.equals(defaults[j].value))
                        break;
               }
           
                                // print input field
                       sb.append("<input type=\"");
                   
                   //if repeatable, print a Checkbox, otherwise print Radio buttons
                   if(repeatable)
                      sb.append("checkbox");
                   else
                      sb.append("radio");
                   if (readonly)
                   {
                       sb.append("\" disabled=\"disabled");
                   }
                   sb.append("\" name=\"")
                     .append(fieldName)
                     .append("\"")
                     .append(j < defaults.length ? " checked=\"checked\" " : "")
                     .append(" value=\"")
                                 .append(value.replaceAll("\"", "&quot;"))
                                 .append("\">");
                   
                   //print display name immediately after input
                   sb.append("&nbsp;")
                     .append(display)
                     .append("<br/>");
                   
                           // if we are writing values in two columns,
                           // then start column 2 after half of the values
                   if((numColumns == 2) && (i+2 >= (valueList.size()/2)) && !inColumn2)
                   {
                        //end first column, start second column
                        sb.append("</td>");
                        sb.append("<td colspan=\"2\" valign=\"top\">");
                        inColumn2 = true;
                   }
                   
            }//end for each value

            sb.append("</td></tr>");
            
            out.write(sb.toString());
          }//end doList
%>

<%
    // Obtain DSpace context
    Context context = UIUtil.obtainContext(request);

    SubmissionInfo si = SubmissionController.getSubmissionInfo(context, request);

    Item item = si.getSubmissionItem().getItem();

    final int halfWidth = 23;
    final int fullWidth = 50;
    final int twothirdsWidth = 34;

    DCInputSet inputSet =
        (DCInputSet) request.getAttribute("submission.inputs");

    Integer pageNumStr =
        (Integer) request.getAttribute("submission.page");
    int pageNum = pageNumStr.intValue();
    
    // for later use, determine whether we are in submit or workflow mode
    String scope = si.isInWorkflow() ? "workflow" : "submit";

    // owning Collection ID for choice authority calls
    int collectionID = si.getSubmissionItem().getCollection().getID();

    // Fetch the document type (dc.type)
    String documentType = "";
    if( (item.getMetadata("dc.type") != null) && (item.getMetadata("dc.type").length >0) )
    {
        documentType = item.getMetadata("dc.type")[0].value;
    }
%>

<dspace:layout locbar="off" navbar="off" titlekey="jsp.submit.edit-metadata.title">

<%
        contextPath = request.getContextPath();
%>



  <form action="<%= request.getContextPath() %>/submit#<%= si.getJumpToField()%>" method="post" name="edit_metadata" id="edit_metadata" onkeydown="return disableEnterKey(event);">

        <jsp:include page="/submit/progressbar.jsp"></jsp:include>

    <h1><fmt:message key="jsp.submit.edit-metadata.heading"/></h1>

<%
     //figure out which help page to display
     if (pageNum <= 1)
     {
%>
        <div><fmt:message key="jsp.submit.edit-metadata.info1"/>
        <dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.index\") + \"#describe2\"%>"><fmt:message key="jsp.submit.edit-metadata.help"/></dspace:popup></div>
<%
     }
     else
     {
%>
        <div><fmt:message key="jsp.submit.edit-metadata.info2"/>
        <dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.index\") + \"#describe3\"%>"><fmt:message key="jsp.submit.edit-metadata.help"/></dspace:popup></div>
    
<%
     }
%>

     <%-- HACK: a <center> tag seems to be the only way to convince certain --%>
     <%--       browsers to center the table. --%>
     <center>
     <table>
<%
         int pageIdx = pageNum - 1;
     DCInput[] inputs = inputSet.getPageRows(pageIdx, si.getSubmissionItem().hasMultipleTitles(),
                                                si.getSubmissionItem().isPublishedBefore() );
     for (int z = 0; z < inputs.length; z++)
     {
       boolean readonly = false;

       // Omit fields not allowed for this document type
       if(!inputs[z].isAllowedFor(documentType))
       {
           continue;
       }

       // ignore inputs invisible in this scope
       if (!inputs[z].isVisible(scope))
       {
           if (inputs[z].isReadOnly(scope))
           {
                readonly = true;
           }
           else
           {
               continue;
           }
       }
       String dcElement = inputs[z].getElement();
       String dcQualifier = inputs[z].getQualifier();
       String dcSchema = inputs[z].getSchema();
       
       String fieldName;
       int fieldCountIncr;
       boolean repeatable;
       String vocabulary;

       vocabulary = inputs[z].getVocabulary();
       
       
       if (dcQualifier != null && !dcQualifier.equals("*"))
          fieldName = dcSchema + "_" + dcElement + '_' + dcQualifier;
       else
          fieldName = dcSchema + "_" + dcElement;


       if ((si.getMissingFields() != null) && (si.getMissingFields().contains(fieldName)))
       {
           if(inputs[z].getWarning() != null)
           {
                   if(si.getJumpToField()==null || si.getJumpToField().length()==0)
                                si.setJumpToField(fieldName);

                   String req = "<tr><td colspan=\"4\" class=\"submitFormWarn\">" +
                                                        inputs[z].getWarning() +
                                                        "<a name=\""+fieldName+"\"></a></td></tr>";
                   out.write(req);
                }
       }
       else
       {
                        //print out hints, if not null
           if(inputs[z].getHints() != null)
           {
                        String hints = "<tr><td colspan=\"4\" class=\"submitFormHelp\">" +
                                                        inputs[z].getHints() +
                                                        "</td></tr>";

                out.write(hints);
                }
       }

       repeatable = inputs[z].getRepeatable();
       fieldCountIncr = 0;
       if (repeatable && !readonly)
       {
         fieldCountIncr = 1;
         if (si.getMoreBoxesFor() != null && si.getMoreBoxesFor().equals(fieldName))
             {
           fieldCountIncr = 2;
         }
       }

       String inputType = inputs[z].getInputType();
       String label = inputs[z].getLabel();
       boolean closedVocabulary = inputs[z].isClosedVocabulary();
       
       if (inputType.equals("name"))
       {
           doPersonalName(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                          repeatable, readonly, fieldCountIncr, label, pageContext, collectionID);
       }
       else if (isSelectable(fieldName))
       {
           doChoiceSelect(out, pageContext, item, fieldName, dcSchema, dcElement, dcQualifier,
                                   repeatable, readonly, inputs[z].getPairs(), label, collectionID);
       }
       else if (inputType.equals("date"))
       {
           doDate(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                          repeatable, readonly, fieldCountIncr, label, pageContext, request);
       }
       else if (inputType.equals("series"))
       {
           doSeriesNumber(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                              repeatable, readonly, fieldCountIncr, label, pageContext);
       }
       else if (inputType.equals("qualdrop_value"))
       {
           doQualdropValue(out, item, fieldName, dcSchema, dcElement, inputSet, repeatable,
                                   readonly, fieldCountIncr, inputs[z].getPairs(), label, pageContext);
       }
       else if (inputType.equals("textarea"))
       {
                   doTextArea(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                  repeatable, readonly, fieldCountIncr, label, pageContext, vocabulary,
                                  closedVocabulary, collectionID);
       }
       else if (inputType.equals("dropdown"))
       {
                        doDropDown(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                   repeatable, readonly, inputs[z].getPairs(), label);
       }
       else if (inputType.equals("twobox"))
       {
                        doTwoBox(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                 repeatable, readonly, fieldCountIncr, label, pageContext, vocabulary,
                                 closedVocabulary);
       }
       else if (inputType.equals("list"))
       {
          doList(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                        repeatable, readonly, inputs[z].getPairs(), label);
       }
       else
       {
                        doOneBox(out, item, fieldName, dcSchema, dcElement, dcQualifier,
                                 repeatable, readonly, fieldCountIncr, label, pageContext, vocabulary,
                                 closedVocabulary, collectionID);
       }
       
       if (hasVocabulary(vocabulary) &&  !readonly)
       {
%>

                <tr>
                        <td>&nbsp;</td>
                        <td colspan="3" class="submitFormHelpControlledVocabularies">
                                <dspace:popup page="/help/index.html#controlledvocabulary"><fmt:message key="jsp.controlledvocabulary.controlledvocabulary.help-link"/></dspace:popup>
                        </td>
                </tr>

<%
                }
%>
<%-- HACK: Using this line to give the browser hints as to the widths of cells --%>
       <tr>
         <td width="40%">&nbsp;</td>
         <td colspan="2" width="5%">&nbsp;</td>
         <td width="40%">&nbsp;</td>
       </tr>

<%
     } // end of 'for rows'
%>
            </table>
        </center>
        
<%-- HACK:  Need a space - is there a nicer way to do this than <BR> or a --%>
<%--        blank <P>? --%>
        <p>&nbsp;</p>

<%-- Hidden fields needed for SubmissionController servlet to know which item to deal with --%>
        <%= SubmissionController.getSubmissionParameters(context, request) %>
        <center>
            <table border="0" width="80%">
                <tr>
                    <td width="100%">&nbsp;</td>
                <%  //if not first page & step, show "Previous" button
                                        if(!(SubmissionController.isFirstStep(request, si) && pageNum<=1))
                                        { %>
                    <td>
                                                <input type="submit" name="<%=AbstractProcessingStep.PREVIOUS_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.previous"/>" />
                    </td>
                                <%  } %>
                    <td>
                        <input type="submit" name="<%=AbstractProcessingStep.NEXT_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.next"/>"/>
                    </td>
                    <td>&nbsp;&nbsp;&nbsp;</td>
                    <td align="right">
                        <input type="submit" name="<%=AbstractProcessingStep.CANCEL_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.cancelsave"/>"/>
                    </td>
                </tr>
            </table>
        </center>
    </form>

</dspace:layout>
