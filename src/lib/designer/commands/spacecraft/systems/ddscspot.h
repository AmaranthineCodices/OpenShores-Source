
#ifndef DdScSpot_H
#define DdScSpot_H

#include "ddcommand.h"
#include "auscparts.h"

class DdScSpot : public DdCommand
{
private:
	bool								m_Vehicle;
	float								m_Rot;
	COMMODITYID							m_Commodity;
	AuScItemSpot::SWITCH				m_Switch;

public:
	DdScSpot(AuDesignerView* view, bool vehicle);

	virtual AuPoint CoordinateEntered(const AuPoint& loc, bool fromKeyboard, int keymods);

	virtual bool OnKeyDown(QKeyEvent* e);

	virtual void RenderCursor(const AuMatrix4x4& projection, const AuMatrix4x4& model, DaPerson* sceneAtom, const QPoint& pxCursor,
			AuGLEffects& re, QOpenGLWidget* glw, bool snappedToExistingShape);

	virtual void Start();

	virtual QString WikiTopic() const;

protected:
	bool MakeIt(const AuPoint& loc);
	virtual void UpdatePrompt() const;
};

#endif // DdScSpot_H
