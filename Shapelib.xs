#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <shapelib/shapefil.h>

#undef min
#define min(x, y) ((x)<(y) ? (x) : (y))

MODULE = Geo::Shapelib		PACKAGE = Geo::Shapelib		


SHPHandle 
SHPOpen(pszShapeFile,pszAccess)
	char *pszShapeFile
	char *pszAccess

SV *
SHPGetInfo(hSHP)
	SHPHandle hSHP
	CODE:
	{
		int NShapes;
		int Shapetype;
		double MinBounds[4];
		double MaxBounds[4];
		int count;
		AV *av;
		HV *hv;
		SV *sv;

		SHPGetInfo(hSHP, &NShapes, &Shapetype, MinBounds, MaxBounds);
		if (!(hv = newHV())) goto BREAK;
		if (!(sv = newSViv(NShapes))) goto BREAK;
		hv_store(hv, "NShapes", 7, sv, 0);
		if (!(sv = newSViv(Shapetype))) goto BREAK;
		hv_store(hv, "Shapetype", 9, sv, 0);

		/* Make MinBounds */
		if (!(av = newAV())) goto BREAK;
		for (count = 0; count < 4; count++) {
			if (!(sv = newSVnv(MinBounds[count]))) goto BREAK;
			av_push(av, sv);
		}
		if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
		hv_store(hv, "MinBounds", 9, sv, 0);

		/* Make MaxBounds */
		if (!(av = newAV())) goto BREAK;
		for (count = 0; count < 4; count++) {
			if (!(sv = newSVnv(MaxBounds[count]))) goto BREAK;
			av_push(av, sv);
		}
		if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
		hv_store(hv, "MaxBounds", 9, sv, 0);

		if (!(sv = newRV_noinc((SV *) hv))) goto BREAK;
		goto DONE;
	      BREAK:
		fprintf(stderr,"Out of memory!\n");
		hv = NULL;
	      DONE:
		RETVAL = sv;
	}
  OUTPUT:
    RETVAL

SV *
SHPReadObject(hSHP, which, combine_vertices)
	SHPHandle hSHP
	int which
	int combine_vertices
	CODE:
	{
		HV *hv = NULL;
		SV *sv = NULL;
		AV *av = NULL;
		int count;

		SHPObject *shape = SHPReadObject( hSHP, which );
		if (!shape) goto DONE;

		hv = newHV();
		if (!hv) goto BREAK;

		if (!(sv = newSViv(shape->nSHPType))) goto BREAK;
		hv_store(hv, "SHPType", 7, sv, 0);
		if (!(sv = newSViv(shape->nShapeId))) goto BREAK;
		hv_store(hv, "ShapeId", 7, sv, 0);
		if (!(sv = newSViv(shape->nParts))) goto BREAK;
		hv_store(hv, "NParts", 6, sv, 0);

		/* Make MinBounds */
		if (!(av = newAV())) goto BREAK;
		if (!(sv = newSVnv(shape->dfXMin))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newSVnv(shape->dfYMin))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newSVnv(shape->dfZMin))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newSVnv(shape->dfMMin))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
		hv_store(hv, "MinBounds", 9, sv, 0);

		/* Make MaxBounds */
		if (!(av = newAV())) goto BREAK;
 		if (!(sv = newSVnv(shape->dfXMax))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newSVnv(shape->dfYMax))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newSVnv(shape->dfZMax))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newSVnv(shape->dfMMax))) goto BREAK;
		av_push(av, sv);
		if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
		hv_store(hv, "MaxBounds", 9, sv, 0);

		if (combine_vertices) {
			/* This is the old interface, which makes a separate
			 * array of parts and vertices */

			/* Make array of parts */
			if (!(av = newAV())) goto BREAK;
			for (count = 0; count < shape->nParts; count++) {
				AV *av2;
				if (!(av2 = newAV())) goto BREAK;
				if (!(sv = newSViv(shape->panPartStart[count]))) goto BREAK;
				av_push(av2, sv);
				if (!(sv = newSViv(shape->panPartType[count]))) goto BREAK;
				av_push(av2, sv);
				if (!(sv = newRV_noinc((SV*) av2))) goto BREAK;
				av_push(av, sv);
			}
			if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
			hv_store(hv, "Parts", 5, sv, 0);

			/* Make array of vertices */
			if (!(sv = newSViv(shape->nVertices))) goto BREAK;
			hv_store(hv, "NVertices", 9, sv, 0);
			if (!(av = newAV())) goto BREAK;
			for (count = 0; count < shape->nVertices; count++) {
				AV *av2;
				if (!(av2 = newAV())) goto BREAK;
				if (!(sv = newSVnv(shape->padfX[count]))) goto BREAK;
				av_push(av2, sv);
				if (!(sv = newSVnv(shape->padfY[count]))) goto BREAK;
				av_push(av2, sv);
				if (!(sv = newSVnv(shape->padfZ[count]))) goto BREAK;
				av_push(av2, sv);
				if (!(sv = newSVnv(shape->padfM[count]))) goto BREAK;
				av_push(av2, sv);
				if (!(sv = newRV_noinc((SV*) av2))) goto BREAK;
				av_push(av, sv);
			}
			if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
			hv_store(hv, "Vertices", 8, sv, 0);
		} else {
			/* Make array of parts, each containing an array of vertices */
			if (!(av = newAV())) goto BREAK;
			for (count = 0; count < shape->nParts; count++) {
				HV *hv2;
				AV *av2;
				int count2, num_vertices, first_vertex;

				if (!(hv2 = newHV())) goto BREAK;   /* hv2 represents this part */
				if (!(sv = newSViv(count))) goto BREAK;
				hv_store(hv2, "PartId", 6, sv, 0);
				if (!(sv = newSViv(shape->panPartType[count]))) goto BREAK;
				hv_store(hv2, "PartType", 8, sv, 0);

				/* Make array of vertices for this part */
				first_vertex = shape->panPartStart[count];
				if(count + 1 < shape->nParts)
					num_vertices = shape->panPartStart[count + 1] - first_vertex;
				else
					num_vertices = shape->nVertices - first_vertex;
				if (!(sv = newSViv(num_vertices))) goto BREAK;
				hv_store(hv2, "NVertices", 9, sv, 0);

				if (!(av2 = newAV())) goto BREAK;
				for (count2 = 0; count2 < num_vertices; count2++) {
					AV *av3;

					if (!(av3 = newAV())) goto BREAK;
					if (!(sv = newSVnv(shape->padfX[first_vertex + count2]))) goto BREAK;
					av_push(av3, sv);
					if (!(sv = newSVnv(shape->padfY[first_vertex + count2]))) goto BREAK;
					av_push(av3, sv);
					if (!(sv = newSVnv(shape->padfZ[first_vertex + count2]))) goto BREAK;
					av_push(av3, sv);
					if (!(sv = newSVnv(shape->padfM[first_vertex + count2]))) goto BREAK;
					av_push(av3, sv);

					if (!(sv = newRV_noinc((SV*) av3))) goto BREAK;
					av_push(av2, sv);
				}

				if (!(sv = newRV_noinc((SV*) av2))) goto BREAK;
				hv_store(hv2, "Vertices", 8, sv, 0);

				if (!(sv = newRV_noinc((SV*) hv2))) goto BREAK;
				av_push(av, sv);
			}
			if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
			hv_store(hv, "Parts", 5, sv, 0);
		}

		SHPDestroyObject(shape);
		if (!(sv = newRV_noinc((SV*) hv))) goto BREAK;
		goto DONE;
	      BREAK:
		fprintf(stderr,"Out of memory!\n");
		sv = NULL;
	      DONE:
		RETVAL = sv;
	}
  OUTPUT:
    RETVAL

void
SHPClose(hSHP)
	SHPHandle hSHP

SHPHandle 
SHPCreate(pszShapeFile, nShapeType)
	char *pszShapeFile
	int nShapeType

SHPObject * 
_SHPCreateObject(nSHPType, iShape, nParts, Parts, nVertices, Vertices)
	int nSHPType
	int iShape
	int nParts
	SV *Parts
	int nVertices
	SV *Vertices
	CODE:
	{
		int *panPartStart = NULL;
		int *panPartType = NULL;
		double *padfX = NULL;
		double *padfY = NULL;
		double *padfZ = NULL;
		double *padfM = NULL;
		AV *p = NULL;		
		AV *v = NULL;
		if (nParts) p = (AV *)SvRV(Parts);
		v = (AV *)SvRV(Vertices);
		if (nParts && !(panPartStart = calloc(nParts, sizeof(int)))) goto BREAK;
		if (nParts && !(panPartType = calloc(nParts, sizeof(int)))) goto BREAK;
		if (!(padfX = calloc(nVertices, sizeof(double)))) goto BREAK;
		if (!(padfY = calloc(nVertices, sizeof(double)))) goto BREAK;
		if (!(padfZ = calloc(nVertices, sizeof(double)))) goto BREAK;
		if (!(padfM = calloc(nVertices, sizeof(double)))) goto BREAK;
		if (nParts && (SvTYPE(p) != SVt_PVAV)) {
			fprintf(stderr,"Parts is not a list\n");
			goto BREAK;
		}
		if (v && (SvTYPE(v) != SVt_PVAV)) {
			fprintf(stderr,"Vertices is not a list\n");
			goto BREAK;
		}
		int i;
		int n = nParts;
		if (p) n = min(n,av_len(p));
		for (i = 0; i < n; i++) {
			SV **pa = av_fetch(p, i, 0);
			if (!pa) {
				fprintf(stderr,"NULL value in Parts array at index %i\n", i);
				goto BREAK;
			}
			AV *pi = (AV *)SvRV(*pa);
			if (SvTYPE(pi) == SVt_PVAV) {
				SV **ps = av_fetch(pi, 0, 0);
				SV **pt = av_fetch(pi, 1, 0);
				panPartStart[i] = SvIV(*ps);
				panPartType[i] = SvIV(*pt);
			} else {
				fprintf(stderr,"Parts is not a list of lists\n");
				goto BREAK;
			}
		}
		n = nVertices;
		if (p) n = min(n,av_len(p));
		for (i = 0; i < n; i++) {
			SV **va = av_fetch(v, i, 0);
			if (!va) {
				fprintf(stderr,"NULL value in Vertices array at index %i\n", i);
				goto BREAK;
			}
			AV *vi =(AV *)SvRV(*va);
			if (SvTYPE(vi) == SVt_PVAV) {
				SV **x = av_fetch(vi, 0, 0);
				SV **y = av_fetch(vi, 1, 0);
				SV **z = av_fetch(vi, 2, 0);
				SV **m = av_fetch(vi, 3, 0);
				padfX[i] = SvNV(*x);
				padfY[i] = SvNV(*y);
				if (z) 
					padfZ[i] = SvNV(*z);
				else
					padfZ[i] = 0;
				if (m)
					padfM[i] = SvNV(*m);
				else
					padfM[i] = 0;
			} else {
				fprintf(stderr,"Vertices is not a list of lists\n");
				goto BREAK;
			}
		}
		RETVAL = SHPCreateObject(nSHPType, iShape, nParts, 
			panPartStart, panPartType, nVertices, padfX, padfY, padfZ, padfM);
		goto DONE;
	      BREAK:
		RETVAL = NULL;
	      DONE:
		if (panPartStart) free(panPartStart);
		if (panPartType) free(panPartType);
		if (padfX) free(padfX);
		if (padfY) free(padfY);
		if (padfZ) free(padfZ);
		if (padfM) free(padfM);
	}
  OUTPUT:
    RETVAL

int 
SHPWriteObject(hSHP, iShape, psObject)
	SHPHandle hSHP
	int iShape
	SHPObject *psObject

void 
SHPDestroyObject(psObject)
	SHPObject *psObject

DBFHandle 
DBFOpen(pszDBFFile,pszAccess)
	char *pszDBFFile
	char *pszAccess

SV * 
DBFRead(hDBF, bForceStrings)
	DBFHandle hDBF
	int bForceStrings
	CODE:
	{
		HV *hv = NULL;
		HV *hv2 = NULL;
		SV *sv = NULL;
		AV *av = NULL;
		int num_fields;
		int num_records;
		int record, field;

		if (!(hv = newHV())) goto BREAK;

		num_fields = DBFGetFieldCount(hDBF);
		num_records = DBFGetRecordCount(hDBF);

		/* Build FieldTypes */
		if (!(hv2 = newHV())) goto BREAK;
		for (field = 0; field < num_fields; field++) {
			char field_name[12], *field_type;
			int nothing1, nothing2, iType;	

			iType = DBFGetFieldInfo(hDBF, field, field_name, &nothing1, &nothing2); 

			/* Force Type to String */
			if (1 == bForceStrings)
				iType = FTString;

			switch (iType) { 
			  case FTString:
				field_type = "String";
			  break;
			  case FTInteger:
				field_type = "Integer";
			  break;
			  case FTDouble:
				field_type = "Double";
			  break;
			  default:
				field_type = "Invalid";
			}

			if (!(sv = newSVpv(field_type, 0))) goto BREAK;
			hv_store(hv2, field_name, strlen(field_name), sv, 0);
		}
		if (!(sv = newRV_noinc((SV*) hv2))) goto BREAK;
		hv_store(hv, "FieldTypes", 10, sv, 0);

		/* Build fields */
		if (!(av = newAV())) goto BREAK;
		for (record = 0; record < num_records; record++) {
			if (!(hv2 = newHV())) goto BREAK;
			for (field = 0; field < num_fields; field++) {
				char field_name[12];
				int nothing1, nothing2, iType;	

				iType = DBFGetFieldInfo(hDBF, field, field_name, &nothing1, &nothing2); 

				/* Force Type to String */
				if (1 == bForceStrings)
					iType = FTString;

				switch (iType) { 
				  case FTString:
					if (!(sv = newSVpv((char *)DBFReadStringAttribute(hDBF,record,field),0))) goto BREAK;
				  break;
				  case FTInteger:
					if (!(sv = newSViv(DBFReadIntegerAttribute(hDBF,record,field)))) goto BREAK;
				  break;
				  case FTDouble:
					if (!(sv = newSVnv(DBFReadDoubleAttribute(hDBF,record,field)))) goto BREAK;
				  break;
				}

				hv_store(hv2, field_name, strlen(field_name), sv, 0);
			}
			if (!(sv = newRV_noinc((SV*) hv2))) goto BREAK;
			av_push(av, sv);
		}
		if (!(sv = newRV_noinc((SV*) av))) goto BREAK;
		hv_store(hv, "ShapeRecords", 12, sv, 0);

		goto DONE;
	      BREAK:
		fprintf(stderr,"Out of memory!\n");
		hv = NULL;
	      DONE:
		RETVAL = newRV_noinc((SV *)hv);
	}
  OUTPUT:
    RETVAL

DBFHandle 
DBFCreate(pszDBFFile)
	char *pszDBFFile

int 
_DBFAddField(hDBF, pszFieldName, type, nWidth, nDecimals)
	DBFHandle hDBF
	char *pszFieldName
	int type
	int nWidth
	int nDecimals
	CODE:
	{
		DBFFieldType eType;
		switch (type) {
		case 1: eType = FTString; break;
		case 2: eType = FTInteger; break;
		case 3: eType = FTDouble; break;
		}
		RETVAL = DBFAddField(hDBF, pszFieldName, eType, nWidth, nDecimals);
	}
  OUTPUT:
    RETVAL

int 
DBFWriteIntegerAttribute(hDBF, iShape, iField, nFieldValue)
	DBFHandle hDBF
	int iShape
	int iField
	int nFieldValue

int
DBFWriteDoubleAttribute(hDBF, iShape, iField, dFieldValue)
	DBFHandle hDBF
	int iShape
	int iField
	double dFieldValue

int 
DBFWriteStringAttribute(hDBF, iShape, iField, pszFieldValue)
	DBFHandle hDBF
	int iShape
	int iField
	char *pszFieldValue

void
DBFClose(hDBF)
	DBFHandle hDBF

