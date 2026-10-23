
#include "ddscspot.h"
//
#include "auapp.h"
#include "auclientglobal.h"
#include "auframe.h"
#include "auscspotdlg.h"
#include "audesignerview.h"
#include "dadesigner.h"
#include "daperson.h"
#include <QKeyEvent>

DdScSpot::DdScSpot(AuDesignerView* view, bool vehicle) : DdCommand(view)
{
	m_Vehicle = vehicle;
	m_Rot = 0;
	m_Commodity = CID_Invalid;
	m_Switch = AuScItemSpot::Switch_None;
}

void DdScSpot::Start()
{
	DdCommand::Start();

	AuScSpotDlg dlg(m_Vehicle, m_pWnd);
	if(auApp->Frame()->ExecDialog(dlg) == QDialog::Accepted)
	{
		m_Commodity = dlg.Commodity();
		m_Switch = dlg.Switch();
	}
	else
		Terminate();
}

QString DdScSpot::WikiTopic() const
{
	return m_Vehicle ? "Designer_Menu#Vehicle_Spot" : "Designer_Menu#Item_Spot";
}

void DdScSpot::UpdatePrompt() const
{
	QString prompt;
	prompt = QObject::tr("<html>"
			"<span style=\"color: %2;\">%3 location. "
			"</span>"
			"<span style=\"color: rgb(255, 255, 0);\">[Shift] Left/Right Arrow%1Rotate, </span>"
			"<span style=\"color: rgb(255, 255, 0);\">?%1Help, </span>"
			"<span style=\"color: rgb(255, 255, 0);\">Esc%1Stop. </span>"
			"</html>")
		.arg('=')
		.arg(m_pWnd->palette().color(QPalette::WindowText).name())
		.arg(m_Vehicle ? QObject::tr("Vehicle spot") : QObject::tr("Item spot"));
	m_pWnd->CommandPromptChanged(prompt);
}

AuPoint DdScSpot::CoordinateEntered(const AuPoint& loc, bool fromKeyboard, int keymods)
{
	Q_UNUSED(fromKeyboard);
	Q_UNUSED(keymods);

	MakeIt(loc);

	return loc;
}

void DdScSpot::RenderCursor(const AuMatrix4x4& projection, const AuMatrix4x4& model, DaPerson* sceneAtom,
		const QPoint& pxCursor, AuGLEffects& re, QOpenGLWidget* glw, bool snappedToExistingShape)
{
	const DaDesigner* pde = sceneAtom->FindParentDesignerInEnv();
	if(!pde)
		return;

	AuPoint loc = m_pWnd->FromPixelToDesignPlane(sceneAtom, pxCursor, true, 0);

	AuMatrix4x4 ts;
	sceneAtom->GetTransformRelativeToParent(ts, pde);
	ts = ts.Inverse();

	AuMatrix4x4 pmv = projection * model * ts;

	{
		float rot = m_Rot * DEG2RADf;
		while(rot < -PIf)
			rot += PIf*2;
		while(rot > PIf)
			rot -= PIf*2;

		AuMatrix4x4 trot(pmv);
		trot.Translate(loc);
		trot.Rotate(m_pWnd->DesignPlane().GetRotation());
		trot.RotateZ(rot);

		double halfX, halfY;
		if(m_Vehicle)
		{
			AuScVehicleSpot spot;
			halfX = spot.IconRight();
			halfY = spot.IconFore();
		}
		else
		{
			AuScItemSpot spot;
			halfX = spot.IconRight();
			halfY = spot.IconFore();
		}

		AuPointArray verts;
		verts.append(AuPoint(-halfX, -halfY));
		verts.append(AuPoint(-halfX, halfY));
		verts.append(AuPoint(halfX, halfY));
		verts.append(AuPoint(halfX, -halfY));
		verts.append(AuPoint(-halfX, -halfY));
		verts.append(AuPoint(0, halfY));
		verts.append(AuPoint(halfX, -halfY));

		AuGLVAO vao;
		vao.CreateForLines(re, verts, false, GL_STREAM_DRAW);
		if(vao.VAO())
		{
			re.glDisable(GL_DEPTH_TEST);
			re.glEnable(GL_LINE_SMOOTH);
			re.GLSL().LineShader().Select();
			re.GLSL().LineShader().SetProjectionModelView(trot);
			re.GLSL().LineShader().SetColor(1,1,1,1);

			vao.SelectGL();
			vao.DrawGL(GL_LINE_STRIP);
			vao.DeselectGL();
			vao.DeleteGL();

			re.GLSL().LineShader().Deselect();
			re.glDisable(GL_LINE_SMOOTH);
			re.glEnable(GL_DEPTH_TEST);
		}
	}

	DrawBlip(pmv, loc, m_pWnd->DesignPlane(), re, glw, snappedToExistingShape);
}

bool DdScSpot::OnKeyDown(QKeyEvent* e)
{
	if(DdCommand::OnKeyDown(e))
		return true;

	switch(e->key())
	{
	case Qt::Key_Right:
		if(e->modifiers() & Qt::ShiftModifier)
			m_Rot += -1;
		else
			m_Rot += -10;
		break;

	case Qt::Key_Left:
		if(e->modifiers() & Qt::ShiftModifier)
			m_Rot += 1;
		else
			m_Rot += 10;
		break;

	default:
		break;
	}

	return false;
}

bool DdScSpot::MakeIt(const AuPoint& loc)
{
	if(m_Commodity == CID_Invalid)
		return false;

	if(m_Vehicle)
	{
		AuScVehicleSpot spot;
		spot.SetCommodity(m_Commodity);
		spot.SetRotation(m_Rot*DEG2RADf);
		spot.MakeIcon(loc, m_Rot*DEG2RADf, m_pWnd->DesignPlane());
		if(!spot.IsValid())
			return false;
		spot.SetArchitect(m_pWnd->SceneAtomId(), m_pWnd->SceneAtomName());
		auApp->DesignerPartAdd(spot);
	}
	else
	{
		AuScItemSpot spot;
		spot.SetCommodity(m_Commodity);
		spot.SetSwitch(m_Switch);
		spot.SetRotation(m_Rot*DEG2RADf);
		spot.MakeIcon(loc, m_Rot*DEG2RADf, m_pWnd->DesignPlane());
		if(!spot.IsValid())
			return false;
		spot.SetArchitect(m_pWnd->SceneAtomId(), m_pWnd->SceneAtomName());
		auApp->DesignerPartAdd(spot);
	}
	return true;
}
