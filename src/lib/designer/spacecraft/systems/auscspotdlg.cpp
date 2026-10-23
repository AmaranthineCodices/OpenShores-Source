
#include "auscspotdlg.h"
//
#include "auclientglobal.h"
#include "davehicle.h"
#include <QComboBox>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>

AuScSpotDlg::AuScSpotDlg(bool vehicles, QWidget* parent) : AuDialog(parent)
{
	m_Vehicles = vehicles;
	m_Initial = CID_Invalid;
	m_InitialSwitch = AuScItemSpot::Switch_None;
	setAuDlgTitle(vehicles ? tr("Vehicle Spot") : tr("Item Spot"));
	setAuDlgIcon(QIcon(":data/SoHDesignerIcon.png"));

	QLabel* lbinfo = new QLabel(vehicles ?
			tr("Choose the vehicle that parks at this spot. A new vehicle of this kind is parked here when it is made, "
				"or fetched to it when one is available.") :
			tr("Choose the item placed at this spot. When the spot is empty, one of these is taken from the ship's or "
				"building's cargo and placed here."), this);
	lbinfo->setWordWrap(true);

	m_Commodities = new QComboBox(this);

	m_Switch = new QComboBox(this);
	m_Switch->addItem(AuScItemSpot::SwitchName(AuScItemSpot::Switch_None), AuScItemSpot::Switch_None);
	m_Switch->addItem(AuScItemSpot::SwitchName(AuScItemSpot::Switch_Off), AuScItemSpot::Switch_Off);
	m_Switch->addItem(AuScItemSpot::SwitchName(AuScItemSpot::Switch_On), AuScItemSpot::Switch_On);
	m_Switch->setToolTip(tr("<html>Whether the placed item starts switched on or off, for items that can be switched.</html>"));
	QLabel* lbswitch = new QLabel(tr("Switch"), this);
	lbswitch->setVisible(!vehicles);
	m_Switch->setVisible(!vehicles);

	QPushButton* pbok = new QPushButton(tr("Ok"), this);
	connect(pbok, SIGNAL(clicked()), SLOT(DoOk()));

	QHBoxLayout* slay = new QHBoxLayout;
	slay->addWidget(lbswitch);
	slay->addWidget(m_Switch, 1);
	slay->setMargin(0);
	slay->setSpacing(2);

	QHBoxLayout* blay = new QHBoxLayout;
	blay->addStretch();
	blay->addWidget(pbok);
	blay->setMargin(0);
	blay->setSpacing(2);

	QVBoxLayout* lay = new QVBoxLayout;
	lay->addWidget(lbinfo);
	lay->addWidget(m_Commodities);
	lay->addLayout(slay);
	lay->addLayout(blay);
	lay->addStretch();
	lay->setMargin(4);
	lay->setSpacing(2);
	setAuDlgLayout(lay);
}

AuScSpotDlg::~AuScSpotDlg()
{
}

void AuScSpotDlg::setVisible(bool visible)
{
	if(visible)
	{
		AuDialog::setVisible(visible);
		RestoreGeometry();
		ListCommodities();
	}
	else if(isVisible())
	{
		SaveGeometry();
		AuDialog::setVisible(visible);
	}
}

void AuScSpotDlg::RestoreGeometry()
{
	int posX = g_Au.Settings().readNumEntry("Widget/ScSpotDlg/PosX",-123);
	int posY = g_Au.Settings().readNumEntry("Widget/ScSpotDlg/PosY",-123);
	QSize szdef = sizeHint();
	int sizeX = g_Au.Settings().readNumEntry("Widget/ScSpotDlg/SizeX",szdef.width());
	int sizeY = g_Au.Settings().readNumEntry("Widget/ScSpotDlg/SizeY",szdef.height());
	resize(sizeX, sizeY);
	if(posX != -123 && posY != -123)
		move(posX, posY);
}

void AuScSpotDlg::SaveGeometry()
{
	QPoint ps = pos();
	QSize sz = size();
	g_Au.Settings().writeEntry("Widget/ScSpotDlg/PosX",ps.x());
	g_Au.Settings().writeEntry("Widget/ScSpotDlg/PosY",ps.y());
	g_Au.Settings().writeEntry("Widget/ScSpotDlg/SizeX",sz.width());
	g_Au.Settings().writeEntry("Widget/ScSpotDlg/SizeY",sz.height());
}

void AuScSpotDlg::DoOk()
{
	if(Commodity() == CID_Invalid)
		return;
	accept();
}

COMMODITYID AuScSpotDlg::Commodity() const
{
	if(m_Commodities->currentIndex() < 0)
		return CID_Invalid;
	return (COMMODITYID)m_Commodities->itemData(m_Commodities->currentIndex()).toInt();
}

AuScItemSpot::SWITCH AuScSpotDlg::Switch() const
{
	if(m_Vehicles || m_Switch->currentIndex() < 0)
		return AuScItemSpot::Switch_None;
	return (AuScItemSpot::SWITCH)m_Switch->itemData(m_Switch->currentIndex()).toInt();
}

void AuScSpotDlg::SetChoice(COMMODITYID cid, AuScItemSpot::SWITCH sw)
{
	m_Initial = cid;
	m_InitialSwitch = sw;
}

void AuScSpotDlg::ListCommodities()
{
	m_Commodities->clear();
	for(DbCommodityArray::const_iterator ci = g_Au.m_CommodityArray.cbegin(); ci != g_Au.m_CommodityArray.cend(); ci++)
	{
		COMMODITYID cid = (COMMODITYID)(*ci).m_id;
		if(cid <= CID_Invalid)
			continue;
		if(m_Vehicles)
		{
			if(!DbCommodity::IsVehicle(cid) || DaVehicle::ParkingSpotType(cid) == SPOT_Invalid)
				continue;
		}
		else
		{
			if(DbCommodity::IsVehicle(cid) || cid == CID_Money || DbCommodity::IsPatent(cid))
				continue;
		}
		m_Commodities->addItem(QIcon((*ci).BitmapName()), (*ci).m_name, (*ci).m_id);
	}
	int i = m_Commodities->findData((int)m_Initial);
	if(i >= 0)
		m_Commodities->setCurrentIndex(i);
	i = m_Switch->findData((int)m_InitialSwitch);
	if(i >= 0)
		m_Switch->setCurrentIndex(i);
}
