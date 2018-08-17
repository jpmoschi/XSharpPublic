﻿//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//

USING System
USING System.Collections.Generic
USING System.Linq
USING System.Text
USING XUnit

BEGIN NAMESPACE XSharp.Core.Tests
	CLASS StringTests
	[Fact, Trait("Category", "String")];
	METHOD AdjustFNameTest() AS VOID
		Assert.Equal("    xyz   ddss.dbf",AdjustFName("    xyz   ddss    .dbf"))
		Assert.Equal(null,AdjustFName(null))
		Assert.Equal(" abc ced",AdjustFName(" abc ced   "))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD AllTrimTest() AS VOID

		LOCAL s := e" Hello World  " AS STRING

		Assert.Equal("Hello World",AllTrim(s))
		Assert.Equal(null,AllTrim(null))

		s:= "Hello World    "
		Assert.Equal("Hello World",AllTrim(s))
				
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD AscTest() AS VOID
		LOCAL VALUE := " 123" AS STRING
		Assert.Equal((DWORD)32,Asc(VALUE))
		LOCAL nOld AS LONG
		nOld := RuntimeState.DosCodePage 
		RuntimeState.DosCodePage := 737 // Greek
		Assert.Equal((DWORD)150,Asc("Ψ"))  
		RuntimeState.DosCodePage := 437 // US
		Assert.Equal((DWORD)63,Asc("Ψ"))  // ? because not defined for the codepage
		RuntimeState.DosCodePage := nOld
		Assert.Equal((DWORD)32,Asc(" "))
		Assert.Equal((DWORD)63,Asc(((CHAR) 512):ToString())) // ?
		Assert.Equal((DWORD)0,Asc(null))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD AscWTest() AS VOID
		LOCAL VALUE := " 123" AS STRING
		Assert.Equal((DWORD)32,AscW(VALUE))
		Assert.Equal((DWORD)955,AscW("λ"))
		Assert.Equal((DWORD)936,AscW("Ψ"))  
		Assert.Equal((DWORD)32,AscW(" "))
		Assert.Equal((DWORD)512,AscW(((CHAR) 512):ToString()))
		Assert.Equal((DWORD)0,AscW(null))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD AscATest() AS VOID
		LOCAL VALUE := " 123" AS STRING
		Assert.Equal((DWORD)32,AscA(VALUE))
		Assert.Equal((DWORD)32,AscA(" "))
		LOCAL nOld AS LONG
		nOld := RuntimeState.WinCodePage 
		RuntimeState.WinCodePage := 1253 // Greek
		Assert.Equal((DWORD)235,AscA("λ"))
		RuntimeState.WinCodePage  := 1252 // Western Europea
		Assert.Equal((DWORD)63,Asc("λ"))	// ? because not defined for the codepage
		RuntimeState.WinCodePage  := nOld
		Assert.Equal((DWORD)0,AscA(null))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD AtTest() AS VOID
		VAR time := "16:55:23"
		Assert.Equal((DWORD)4,At("55",time))
		Assert.Equal((DWORD)0,At("55",null))
		Assert.Equal((DWORD)0,At(null,time))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD At2Test() AS VOID
		VAR time := "16:55:23"
		Assert.Equal((DWORD)4,At2("55",time))
		Assert.Equal((DWORD)0,At2("55",null))
		Assert.Equal((DWORD)0,At2(null,time))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD AtCTest() AS VOID
		Assert.Equal((DWORD)7,AtC("World","Hello World"))
		Assert.Equal((DWORD)7,AtC("world","Hello World"))
		Assert.Equal((DWORD)0,At("world","Hello World"))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD AtC2Test() AS VOID
		Assert.Equal((DWORD)7,AtC2("World","Hello World"))
		Assert.Equal((DWORD)7,AtC2("world","Hello World"))
		Assert.Equal((DWORD)0,At2("world","Hello World"))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD At3Test() AS VOID
		VAR time := "16:25:23"
		Assert.Equal((DWORD)7,At3("2",time,5))
		Assert.Equal((DWORD)0,At3("2",time,12))

	RETURN


	[Fact, Trait("Category", "String")];
	METHOD CharEvenTest() AS VOID
		Assert.Equal("1234",CharEven("A1B2C3D4"))
		Assert.Equal("1234",CharEven("A1B2C3D4E"))
		Assert.Equal(null,CharEven(null))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD CharOddTest() AS VOID
		Assert.Equal("ABCD",CharOdd("A1B2C3D4"))
		Assert.Equal("ABCDE",CharOdd("A1B2C3D4E"))
		Assert.Equal(null,CharOdd(null))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD CharPosTest() AS VOID
		Assert.Equal("o",CharPos("Hello World",5))
		Assert.Equal(String.Empty,CharPos("A1B2C3D4E",33))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD HardCRTest() AS VOID
		LOCAL s AS STRING
		s := "aaa" + ((CHAR) 141):ToString() +chr(10)+ "bbb"
		Assert.Equal(1U, MlCount1(s))
		Assert.Equal(2U, MlCount1(HardCR(s)))
	

	[Fact, Trait("Category", "String")];
	METHOD InStrTest() AS VOID
		Assert.Equal(true,Instr("o W","Hello World"))
		Assert.Equal(false,Instr("o w","Hello World"))
		Assert.Equal(false,Instr(null,null))
		Assert.Equal(false,Instr("w",null))
		Assert.Equal(false,Instr(null,"w"))
	RETURN


	[Fact, Trait("Category", "String")];
	METHOD StringIsTest() AS VOID
	//

	Assert.Equal(true,IsAlpha("A"))
	Assert.Equal(true,IsAlNum("A"))
	Assert.Equal(false,IsAlpha("9"))
	Assert.Equal(true,IsDigit("9"))
	Assert.Equal(true,IsXDigit("9"))
	Assert.Equal(true,IsBDigit("0"))
	Assert.Equal(true,IsBDigit("1"))
	Assert.Equal(false,IsBDigit("2"))
	Assert.Equal(false,IsUpper("2"))
	Assert.Equal(false,IsUpper("a"))
	Assert.Equal(true,IsUpper("A"))
	Assert.Equal(false,IsLower("2"))
	Assert.Equal(false,IsLower("A"))
	Assert.Equal(true,IsLower("a"))
	Assert.Equal(true,IsSpace(" "))
	Assert.Equal(true,IsSpace(e"\t"))
	Assert.Equal(true,IsSpace(e"\r"))
	Assert.Equal(true,IsSpace(e"\v"))
	Assert.Equal(true,IsSpace(e"\n"))
	Assert.Equal(false,IsSpace("A"))


	[Fact, Trait("Category", "String")];
	METHOD LeftTest() AS VOID

		LOCAL s := "Hello World" AS STRING
		LOCAL unassigned		 AS STRING		                  
							  
		Assert.Equal("",left(s,0))
		Assert.Equal("H",left(s,1))
		Assert.Equal("Hello World",left(s,99))

		Assert.Equal(null,left(unassigned,0))
		Assert.Equal(null,left(unassigned,1))
		Assert.Equal(null,left(unassigned,99))
				
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD LowerTest() AS VOID
		Assert.Equal("hello world",Lower("Hello World"))
		Assert.Equal(null,Lower(null))
		VAR s := "Hello World"
		lowerA(s)
		Assert.Equal("hello world",s)
	RETURN


	[Fact, Trait("Category", "String")];
	METHOD LenTest() AS VOID
		Assert.Equal(0U, SLen(""))
		Assert.Equal(0U, SLen(null))
		Assert.Equal(1U, SLen("x"))
		Assert.Equal(5U, SLen("12345"))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD LTrimTest() AS VOID
		Assert.Equal("Hello World",LTrim("    Hello World"))
		Assert.Equal(null,Lower(null))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD OccursTest() AS VOID
		Assert.Equal((DWORD)2,Occurs("or","the world according to me"))
		Assert.Equal((DWORD)0,Occurs(null,null))
		Assert.Equal((DWORD)0,Occurs("x",null))
		Assert.Equal((DWORD)0,Occurs(null,"xx"))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD Occurs3Test() AS VOID
		Assert.Equal((DWORD)1,Occurs3("or","the world according to me",7))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD ProperTest() AS VOID
		Assert.Equal("Hello World",Proper("hello world"))
		Assert.Equal(null,Proper(null))
		Assert.Equal(Proper("1st characters are in uppercase"), "1st Characters Are In Uppercase")

	RETURN

	[Fact, Trait("Category", "String")];
	METHOD RAtTest() AS VOID
		Assert.Equal((DWORD)14,RAt("or","the world according to me"))
		Assert.Equal((DWORD)0,Rat(null,null))
		Assert.Equal((DWORD)0,Rat("or",null))
		Assert.Equal((DWORD)0,Rat(null,"the world"))
	RETURN


	[Fact, Trait("Category", "String")];
	METHOD RAtLineTest() AS VOID
	  LOCAL cSource AS STRING

	  cSource := e"This is the first line\r\nThis is the second line\r\nThis is the third line"

	  Assert.Equal(3U, RAtLine("line", cSource) )
	  Assert.Equal(2U, RAtLine("second line", cSource) )

	  Assert.Equal(3U, RAtLine2("line", cSource) )
	  Assert.Equal(2U, RAtLine2("second line", cSource) )
	  RETURN

	[Fact, Trait("Category", "String")];
	METHOD RAt2Test() AS VOID
		Assert.Equal((DWORD)14,RAt2("or","the world according to me"))
		Assert.Equal((DWORD)0,Rat2(null,null))
		Assert.Equal((DWORD)0,Rat2("or",null))
		Assert.Equal((DWORD)0,Rat2(null,"the world"))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD RAt3Test() AS VOID
		Assert.Equal((DWORD)14,RAt3("or","the world according to me",9))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD ReplicateTest() AS VOID
		Assert.Equal("dudadudaduda",Replicate("duda",3))
		Assert.Equal("dudadudaduda",Repl("duda",3))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD RTrimTest() AS VOID
		Assert.Equal("    Hello World",RTrim("    Hello World     "))
		Assert.Equal(null,RTrim(null))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD RightTest() AS VOID
		Assert.Equal("World",Right("Hello World",5))
		Assert.Equal(null,Right(null,0))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD SCloneTest() AS VOID
		LOCAL s:="Hello World" AS STRING
		Assert.Equal(s,SClone(s))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD SLenTest() AS VOID
		LOCAL s:="Hello World" AS STRING
		VAR l := SLen(s)
		Assert.Equal((DWORD)11,SLen(s))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD SLenExceptionTest() AS VOID
		LOCAL s AS STRING
		s:=string.Empty
		//XUnit.Assert.Throws<InvalidOperationException>( () => SLen(s))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD StuffTest() AS VOID
		LOCAL s:="Hello World" AS STRING
		Assert.Equal("Hello Kiel",Stuff(s,7,5,"Kiel"))
		Assert.Equal("Kiel",Stuff(null,7,5,"Kiel"))
		Assert.Equal("Hello ",Stuff(s,7,5,""))
		Assert.Equal("Hello WorldKiel",Stuff(s,12,5,"Kiel"))
	RETURN

	[Fact, Trait("Category", "String")];
	METHOD SubStr2Test() AS VOID
		LOCAL s:="Hello World" AS STRING
		Assert.Equal("World",SubStr2(s,7))
		Assert.Equal("",SubStr2(s,20))
		Assert.Equal(null,SubStr2(null,5))
	RETURN
	[Fact, Trait("Category", "String")];
	METHOD SubStr3Test() AS VOID
		LOCAL s:="Hello World" AS STRING
		Assert.Equal("World",SubStr3(s,7,5))
		Assert.Equal("",SubStr3(s,20,5))
		Assert.Equal(null,SubStr3(null,5,2))
	RETURN
	[Fact, Trait("Category", "String")];
	METHOD TrimTest() AS VOID
		LOCAL s:="Hello World   " AS STRING
		Assert.Equal("Hello World",Trim(s))
		Assert.Equal(null,Trim(null))
	RETURN
	[Fact, Trait("Category", "String")];
	METHOD UpperTest() AS VOID
		LOCAL s:="Hello World" AS STRING
		Assert.Equal("HELLO WORLD",Upper(s))
		Assert.Equal(null,Upper(null))
		upperA(s)
		Assert.Equal("HELLO WORLD",s)
	RETURN

   [Fact, Trait("Category", "String")];
   METHOD SoundExTest() AS VOID
	  Assert.Equal("F631", SoundEx("Fred Bloggs")  )
	  Assert.Equal("S530", SoundEx("Smith")  )
	  Assert.Equal("S530", SoundEx("Smythe") )

	  RETURN
   
   [Fact, Trait("Category", "String")];
   METHOD CharMixTest() AS VOID
	  Assert.Equal("1234567890", CHarMix("13579","24680"))
	  Assert.Equal("", CHarMix("","24680"))
	  Assert.Equal("12", CHarMix("1","24680"))
	  Assert.Equal("", CHarMix("13579",""))
	  Assert.Equal("1232527292", CHarMix("13579","2"))

	  RETURN
   [Fact, Trait("Category", "Memo")];
   METHOD AtLineTest() AS VOID
	  LOCAL test AS STRING
	  test := e"first line\r\nsecond line\r\nthird line"
	  Assert.Equal(1U, AtLine("first", test))
	  Assert.Equal(2U, AtLine("second", test))
	  Assert.Equal(3U, AtLine("third", test))
	  Assert.Equal(0U, AtLine("fourth", test))
	  Assert.Equal(1U, AtCLine("First", test))
	  Assert.Equal(2U, AtCLine("Second", test))
	  Assert.Equal(3U, AtCLine("Third", test))
	  Assert.Equal(0U, AtCLine("Fourth", test))
	 
	  RETURN

   [Fact, Trait("Category", "Memo")];
   METHOD MemLinesTest() AS VOID
	  LOCAL test AS STRING
	  test := e"first line\r\nsecond line\r\nthird line"
	  Assert.Equal(3U, MemLines(test))     
	  Assert.Equal(3U, MlCount1(test))     
	  Assert.Equal(0U, MemLines(""))
	  Assert.Equal(1U, MemLines(" "))
	  Assert.Equal(0U, MlCount1(""))
	  Assert.Equal(1U, MlCount1(" "))
	  Assert.Equal(0U, MemLines(null))  
	  Assert.Equal(0U, MlCount1(NULL))  
	  RETURN



   [Fact, Trait("Category", "Memo")];
	METHOD MemoTest() AS VOID
		LOCAL sToWrite := "test" AS STRING
		MemoWrit("test.txt", sToWrite)
		VAR sText := System.IO.File.ReadAllText("test.txt")
		Assert.Equal(sToWrite, sText)
		sText := MemORead("test.txt")
		Assert.Equal(sToWrite, sText)
		END CLASS

END NAMESPACE