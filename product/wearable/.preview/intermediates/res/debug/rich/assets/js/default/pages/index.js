/******/ (() => { // webpackBootstrap
var __webpack_exports__ = {};
/*!**************************************************************************************************!*\
  !*** E:\20220307\camera\camera_0112\product\wearable\src\main\ets\default\pages\index.ets?entry ***!
  \**************************************************************************************************/
class Index extends View {
    constructor(compilerAssignedUniqueChildId, parent, params) {
        super(compilerAssignedUniqueChildId, parent);
        this.updateWithValueParams(params);
    }
    updateWithValueParams(params) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id());
    }
    render() {
        Flex.create({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center });
        Flex.debugLine("pages/index.ets(20:5)");
        Flex.width('100%');
        Flex.height('100%');
        Text.create('Hello World');
        Text.debugLine("pages/index.ets(21:7)");
        Text.fontSize(50);
        Text.fontWeight(FontWeight.Bold);
        Text.pop();
        Flex.pop();
    }
}
loadDocument(new Index("1", undefined, {}));

/******/ })()
;