#include <d2d1.h>

#include "direct2d.h"


gr::Direct2d::Direct2d() : factory(nullptr),
                           render_target(nullptr) {
}

gr::Direct2d::~Direct2d() {
    if (factory) {
        factory->Release();
    }
    if (render_target) {
        render_target->Release();
    }
}

HRESULT gr::Direct2d::Initialize(HWND hwnd) {
    HRESULT res = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &factory);
    if (res != S_OK) {

        return 1;
    }
    RECT client_rect;
    GetClientRect(hwnd, &client_rect);
    res = factory->CreateHwndRenderTarget(D2D1::RenderTargetProperties(),
                                          D2D1::HwndRenderTargetProperties(hwnd, D2D1::SizeU(client_rect.right -
                                                                                                     client_rect.left,
                                                                                             client_rect.bottom -
                                                                                                     client_rect.top)),
                                          &render_target);
    if (res != S_OK) {

        return 1;
    }

    return 0;
}

void gr::Direct2d::BeginDraw() {
    render_target->BeginDraw();
}

void gr::Direct2d::EndDraw() {
    render_target->EndDraw();
}
