#include <d2d1.h>
#include <d2d1_1.h>
#include <windows.h>

namespace gr {
    class Direct2d {
    public:
        ID2D1Factory* factory;
        ID2D1HwndRenderTarget* render_target;

        Direct2d();

        ~Direct2d();

        void BeginDraw();

        void EndDraw();

        HRESULT Initialize(HWND hwnd);
    };

}// namespace gr
