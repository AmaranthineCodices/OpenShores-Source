
#ifndef AuScSpotDlg_H
#define AuScSpotDlg_H

#include "audialog.h"
#include "auscparts.h"

class QComboBox;

class AuScSpotDlg : public AuDialog
{
	Q_OBJECT;
	bool								m_Vehicles;
	COMMODITYID							m_Initial;
	AuScItemSpot::SWITCH				m_InitialSwitch;
	QComboBox*							m_Commodities;
	QComboBox*							m_Switch;

public:
	AuScSpotDlg(bool vehicles, QWidget* parent=0);
	virtual ~AuScSpotDlg();

	COMMODITYID Commodity() const;

	void SetChoice(COMMODITYID cid, AuScItemSpot::SWITCH sw);

	AuScItemSpot::SWITCH Switch() const;

public slots:
	virtual void setVisible(bool visible);

protected:
	void ListCommodities();
	void RestoreGeometry();
	void SaveGeometry();

protected slots:
	void DoOk();
};

#endif // AuScSpotDlg_H
