USING System.Collections
USING System.Collections.Generic
USING System.Windows.Forms
USING System.IO
USING Xide
USING XSharpModel
USING System.Reflection

BEGIN NAMESPACE XSharp.VOEditors
CLASS XSharp_VODbServerEditor INHERIT VODbServerEditor
	PROTECT oXProject as XProject

	CONSTRUCTOR(_oSurface AS Control , _oGrid AS DesignerGrid )
		SUPER(_oSurface , _oGrid) 
		oXProject  := NULL_OBJECT
	RETURN

	METHOD Open(cFileName as STRING) AS LOGIC
		LOCAL oFile as XFile
		local lOk as LOGIC
		oFile := XSharpModel.XSolution.FindFile(cFileName)
		if (oFile != NULL_OBJECT)
			oXProject := oFile:Project
		endif
		if oXProject == NULL
			XFuncs.ErrorBox("Cannot find project for file "+cFileName)
			RETURN FALSE
		ENDIF
		SELF:ReadAllAvailableFieldSpecs(Funcs.GetModuleFilenameFromBinary(cFileName))
		SELF:aFilesToDelete:Clear()
		SELF:cLoadedDir := FileInfo{cFileName}:DirectoryName
		SELF:cDefaultFileName := cFileName
		SELF:lLoading := TRUE
		lOk := SELF:OpenXML(cFileName)
		IF (! lOk)
			TRY
				lOk := SELF:OpenVNDBS(cFileName)
			CATCH
			END TRY
		ENDIF
		SELF:lLoading := FALSE
		IF lOk
			SELF:oSurface:Controls:Add(SELF:oPanel)
			SELF:oGrid:PropertyModified := self:oPropertyUpdatedHandler
			SELF:oGrid:ControlKeyPressed := SELF:oControlKeyPressedHandler
			SELF:InitReadonlyProperties()
			SELF:GiveFocus()
		ENDIF
		RETURN lOk
	METHOD GetAvailableFieldSpec(cFieldSpec as STRING) AS FSEDesignFieldSpec
		IF aAvailableFieldSpecs == NULL
			aAvailableFieldSpecs  := ArrayList{}
		ENDIF
		FOREACH oFs as FSEDesignFieldSpec in aAvailableFieldSpecs
			if String.Equals(oFS:Name, cFieldSpec, StringComparison.OrdinalIgnoreCase) 
				return oFS
			ENDIF
		NEXT
		RETURN NULL
	METHOD ReadAllAvailableFieldSpecs(cModule as STRING) AS VOID
		local aFiles as IList<XFile>
		SELF:aAvailableFieldSpecs:Clear()
		SELF:aFieldSpecsInModule:Clear()
		aFiles := XFuncs.FindItemsOfType(oXProject, XFileType.VOFieldSpec, NULL)
		FOREACH oFile as XFile in aFiles
			LOCAL cName as STRING
			LOCAL lInModule as LOGIC
			cName	  := oFile:FullPath
			lInModule := Funcs.GetModuleFileNameFromBinary(cName):ToUpper() == cModule:ToUpper()
			if cName:ToUpper():Contains(".FIELDSPECS.VNFS") .or. ;
				cName:ToUpper():Contains(".FIELDSPECS.XSFS")
				VAR aFS := VOFieldSpecEditor.OpenXML(cName, NULL)
				self:aAvailableFieldSpecs:AddRange(aFs)
				if (lInModule)
					SELF:aFieldSpecsInModule:AddRange(aFs)		
				endif
			ELSE
				LOCAL fs as FSEDesignFieldSpec
				fs := VOFieldSpecEditor.OPenVNFS(cName, (VOFieldSpecEditor) NULL)
				SELF:aAvailableFieldspecs:Add(fs)
				if (lInModule)
					SELF:aFieldSpecsInModule:Add(fs)		
				endif
			ENDIF			
		NEXT

	PROTECTED METHOD GetSaveFileStreams(cSrvFileName AS STRING , oPrgStream AS EditorStream, lVnfrmOnly AS LOGIC) AS LOGIC
		LOCAL cPrgFileName AS STRING
		LOCAL lSuccess AS LOGIC
		LOCAL lError AS LOGIC
		
		TRY

			cPrgFileName := Funcs.GetModuleFilenameFromBinary(cSrvFileName) + ".prg"
			lError := FALSE
			IF !lVnfrmOnly
				IF !File.Exists(cPrgFileName)
					XFuncs.ErrorBox("File was not found : " + cPrgFileName , "DBServer Editor")
					lError := TRUE
				END IF
			END IF
			
			lSuccess := FALSE
			IF !lError
				IF !lVnfrmOnly
					oPrgStream:Load(cPrgFileName)
					lSuccess := oPrgStream:IsValid
				ELSE
					lSuccess := TRUE
				END IF
			END IF
			
		CATCH e AS Exception

			XFuncs.ErrorBox(e:Message )
			lSuccess := FALSE

		END TRY

		IF !lSuccess
			IF oPrgStream:IsValid
				oPrgStream:Close()
			ENDIF
		END IF

	RETURN lSuccess
	
	METHOD Save(cFileName AS STRING , lSrvOnly AS LOGIC) AS LOGIC
		LOCAL oPrgStream AS XSharp_EditorStream
		LOCAL lSaveFieldSpecs := FALSE AS LOGIC
		LOCAL oCode AS CodeContents
		LOCAL cFieldSpec AS STRING
		LOCAL aCode AS ArrayList
		LOCAL cModule AS STRING
		LOCAL lSuccess := FALSE AS LOGIC
		LOCAL lAutoRecover AS LOGIC
		
		lAutoRecover := lSrvOnly .or. cFileName:ToUpper():Contains("~AUTORECOVER")

		IF SELF:oFileNameEdit:Focused
		   IF SELF:oFileNameEdit:Text:Trim() != SELF:oMainDesign:GetProperty("filename"):TextValue
				SELF:StartAction(DesignerBasicActionType.SetProperty , ActionData{SELF:oMainDesign:cGuid , "filename" , SELF:oFileNameEdit:Text:Trim()})
			ENDIF
		ENDIF
		
		IF lAutoRecover
			TRY
				SELF:SaveToXml(cFileName)
				lSuccess := TRUE
			END TRY
			RETURN lSuccess
		END IF

		IF .not. SELF:CheckIfValid()
			RETURN FALSE
		END IF

		IF !VODBServerEditor.LoadTemplate(SELF:cLoadedDir)
			RETURN FALSE
		ENDIF
		IF !VOFieldSpecEditor.LoadTemplate(SELF:cLoadedDir)
			RETURN FALSE
		ENDIF

		oCode := SELF:GetCodeContents()
		
        cModule := Funcs.GetModuleFilenameFromBinary(cFileName)
		SELF:ReadAllAvailableFieldspecs(cModule)
		VAR aFieldSpecs := SELF:aFieldSpecsInModule

		aCode := ArrayList{}
		VAR aDesign := SELF:GetAllDesignItems(DBServerItemType.Field)
		FOREACH oDesign as DBEDesignDBServer in aDesign
			cFieldSpec := oDesign:GetProperty("classname"):TextValue
			cFieldSpec := cFieldSpec:Trim():ToUpper()
			IF SELF:IsFieldSpecInModule(cFieldSpec)
				lSaveFieldSpecs := TRUE
				FOREACH oFieldSpec as FSEDesignFieldSpec in aFieldSpecs
					IF oFieldSpec:Name:ToUpper() == cFieldSpec
						aCode:Add(oFieldSpec)
						SELF:CopyPropertyValues(oDesign , oFieldSpec)
						EXIT
					END IF
				NEXT
			ELSEIF .not. SELF:IsAvailableFieldSpec(cFieldSpec) // New FieldSpec
				lSaveFieldSpecs := TRUE
				VAR oFieldSpec := FSEDesignFieldSpec{NULL , NULL}
				aCode:Add(oFieldSpec)
				SELF:CopyPropertyValues(oDesign , oFieldSpec)
				aFieldSpecs:Add(oFieldSpec)
			END IF
		NEXT

		IF aFieldSpecs:Count != 0 .and. lSaveFieldSpecs
			LOCAL cFieldSpecFileName as STRING
			cFieldSpecFileName := cModule + ".FieldSpecs.vnfs"
			XFuncs.DeleteFile(oXProject, cFieldSpecFileName)
			cFieldSpecFileName := cModule + ".FieldSpecs.xsfs"
			VOFieldSpecEditor.SaveToXml( cFieldSpecFileName, aFieldSpecs)
			XFuncs.EnsureFileNodeExists(OXProject, cFieldSpecFileName)

			FOREACH oFieldSpec as  FSEDesignFieldSpec in aFieldSpecs
				VAR cFile := oFieldSpec:cVNfsFileName
				IF .not. String.IsNullOrEmpty(cFile) .and. .not. oFieldSpec:cVNfsFileName:ToUpper():Contains(".FIELDSPECS.XSFS")
					XFuncs.DeleteFile(oXProject, cFile)
				END IF
			NEXT
		END IF

		SELF:ReadAllAvailableFieldspecs(cModule)

		lSrvOnly		:= lSrvOnly .or. SELF:lStandalone
		oPrgStream  := XSharp_EditorStream{}
		IF SELF:GetSaveFileStreams(cFileName , oPrgStream , lSrvOnly)
			TRY
				SELF:SaveToXml(cFileName)
				IF !lSrvOnly
					SELF:SavePrg(oPrgStream , oCode , aCode)
				END IF
				lSuccess := TRUE
	
				IF !lSrvOnly
					SELF:nActionSaved := SELF:nAction
				END IF
			END TRY
		END IF
		
		IF lSuccess
			FOREACH cFile as STRING in SELF:aFilesToDelete
				XFuncs.DeleteFile(oXProject, cFile)
			NEXT
			SELF:aFilesToDelete:Clear()
		END IF
		
	RETURN lSuccess

	METHOD ProcessExtraEntity(aLines as List<String>, oGenerator as CodeGenerator, cClass as string, lAdd as LOGIC) as VOID
		LOCAL oTempStream as XSharp_EditorStream
		LOCAL oTempGenerator as CodeGenerator
		oTempStream := XSharp_EditorStream{}
		oTempStream:Load(aLines)
		oTempGenerator := CodeGenerator{oTempStream:Editor}
		VAR oEntity := oTempStream:Editor:GetEntityObject(1)
		IF oEntity != NULL
			IF lAdd
				oGenerator:WriteEntity(oEntity:eType , oEntity:cName , cClass , EntityOptions.None, aLines)
			ELSE
				oGenerator:DeleteEntity(oEntity:eType , oEntity:cName , cClass )
			ENDIF
		END IF
		RETURN 

	METHOD SavePrg(oStream AS XSharp_EditorStream , oCode AS CodeContents , aFieldSpecs AS ArrayList) AS LOGIC
		LOCAL cName AS STRING
		VAR oGenerator := CodeGenerator{oStream:Editor}
		oGenerator:BeginCode()
		
		cName := SELF:oMainDesign:GetProperty("classname"):TextValue
		oGenerator:WriteEntity(EntityType._Class , cName , cName , EntityOptions.AddUser, oCode:aClass)
		oGenerator:WriteEntity(EntityType._Constructor,  cName , cName ,EntityOptions.None , oCode:aConstructor)
		oGenerator:WriteEntity(EntityType._Access,  "FIELDDESC" , cName ,EntityOptions.None , oCode:aFieldDesc)
		oGenerator:WriteEntity(EntityType._Access,  "INDEXLIST" , cName , EntityOptions.None, oCode:aIndexList)

		FOREACH aAdditional as List<String> in oCode:aAdditional
			SELF:ProcessExtraEntity(aAdditional, oGenerator, cName, TRUE)
		NEXT
		//
		SELF:SaveAccessAssign(oGenerator , cName , SELF:oMainDesign:GetProperty("noaccass"):TextValue:ToUpper() == "YES")
		
		FOREACH  oFieldSpec AS FSEDesignFieldSpec IN aFieldSpecs
			oCode := VOFieldSpecEditor.GetCodeContents(oFieldSpec)
			cName := oFieldSpec:GetProperty("classname"):TextValue
			oGenerator:WriteEntity(EntityType._Class ,      cName , cName , EntityOptions.AddUser, oCode:aClass)
			oGenerator:WriteEntity(EntityType._Constructor, cName , cName , EntityOptions.None, oCode:aConstructor)
		NEXT
		oGenerator:WriteEndClass(cName)
		oGenerator:EndCode()
		oStream:Save()
		
	RETURN TRUE
	METHOD SaveAccessAssign(oGenerator AS CodeGenerator, cClass AS STRING , lNoAccAss AS LOGIC) AS VOID
		LOCAL aValues AS NameValueCollection
		LOCAL aDesign AS ArrayList
		LOCAL cValue AS STRING
		LOCAL oMI AS MEthodInfo
		LOCAL oType as System.Type
		
		aDesign := SELF:GetAllDesignItems(DBServerItemType.Field)
		oType := Typeof(VODbServerEditor)
		oMI := oType:GetMethod("TranslateLine", BindingFlags.Static | BindingFlags.NonPublic )
		FOREACH oDesign  as  DBEDesignDBServer in aDesign
			aValues := NameValueCollection{}
			FOREACH oProp as  DesignProperty in oDesign:aProperties
				DO CASE
				CASE oProp:Name == "hlname"
					// it appears that %hlname% tag is translated to %fldname% in VO
					cValue := oDesign:GetProperty("fldname"):TextValue // BIG BAD UGLY HACK
				CASE oProp:cEnumType == "YESNO"
					cValue := iif(oProp:ValueLogic , "TRUE" , "FALSE")
				CASE oProp:Name == "type"
					IF (INT)oProp:Value == 6
						cValue := "X"
					ELSE
						cValue := oProp:TextValue:Substring(0,1)
					END IF
				OTHERWISE
					cValue := oProp:TextValue
				END CASE
				aValues:Add(oProp:Name , cValue)
			NEXT
			
			cValue := oDesign:GetProperty("Type"):TextValue:ToUpper()
			DO CASE
			CASE cValue == "CHARACTER" .or. cValue == "MEMO"
				cValue := "STRING"
			CASE cValue == "NUMERIC"
				cValue := "FLOAT"
			OTHERWISE
				cValue := "USUAL"
			END CASE
			aValues:Add("usualtype" , cValue)
			
			FOREACH aTempEntity AS List<STRING> in VODBServerEditor.Template:aAccessAssign
				VAR aEntity := List<STRING>{}
				FOREACH cLine as STRING IN aTempEntity
					IF (oMI != NULL_OBJECT)
						local cNew as STRING
						cNew := (STRING) oMI:Invoke(NULL_OBJECT, <OBJECT>{cLine, aValues})
						aEntity:Add(cNew)
					ELSE
						aEntity:Add(cLine)
					ENDIF
				NEXT
				LOCAL lDelete := lNoAccAss .or. oDesign:GetProperty("included"):TextValue == "0" as LOGIC
				SELF:ProcessExtraEntity(aEntity, oGenerator, cClass, !lDelete)
			NEXT
		NEXT
		
	RETURN
END CLASS
STATIC CLASS BufferExtensions
		STATIC METHOD GetEntityObject(SELF editor as XSharpBuffer, nItem as LONG) as EntityObject
			local oLine := editor:GetLine(nItem) as LineObject
			IF oLine != NULL .and. oLine:ContainsEntity
				return oLine:LastEntity
			endif
			return NULL_OBJECT
			
END CLASS
END NAMESPACE